import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/ad_helper.dart';
import 'package:reminder/services/noti_service.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/reminder_provider.dart';
import 'package:reminder/services/reminder_model.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  BannerAd? _bannerAd;
  BannerAd? _bannerAd2;

  @override
  void initState() {
    super.initState();
    _loadAds();

    // Ensure provider loads reminders after build (safe to access context)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReminderProvider>();
      provider.loadReminders();
    });
  }

  void _loadAds() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();

    _bannerAd2 = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId2,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  /// Delete using provider so it updates DB + in-memory list (UI updates automatically).
  Future<void> _deleteReminder(Reminder reminder) async {
    final provider = context.read<ReminderProvider>();

    // Perform delete
    await provider.deleteReminder(reminder);

    // Show snackbar with Undo using provider.addReminder()
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reminder.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Re-insert (addReminder will insert to DB and reload)
            await provider.addReminder(reminder);
          },
        ),
      ),
    );
  }

  void _showReminderDialog(Reminder reminder) {
    final isDark = Provider.of<SettingsProvider>(context, listen: false).isDarkmode;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(reminder.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.content.isNotEmpty) Text('Notes: ${reminder.content}'),
            const SizedBox(height: 8),
            Text('DateTime: ${reminder.dateTime}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                context,
                '/add_reminder',
                arguments: reminder,
              );
              // The add/edit screen now uses the provider, but reload if it returns true
              if (result == true) {
                context.read<ReminderProvider>().loadReminders();
              }
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd2?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final reminderProvider = context.watch<ReminderProvider>();
    final reminders = reminderProvider.reminders;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: settings.appBarColor,
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_bannerAd != null)
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          if (_bannerAd2 != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: _bannerAd2!.size.width.toDouble(),
                height: _bannerAd2!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd2!),
              ),
            ),

          // Main content
          reminders.isEmpty
              ? Center(
                  child: Text(
                    'No Reminders Yet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: (_bannerAd?.size.height.toDouble() ?? 0) + 16,
                    left: 16,
                    right: 16,
                    bottom: (_bannerAd2?.size.height.toDouble() ?? 0) + 16,
                  ),
                  itemCount: reminders.length,
                  itemBuilder: (_, index) {
                    final reminder = reminders[index];
                    return Dismissible(
                      key: Key(reminder.id.toString()),
                      background: _buildDismissBg(Alignment.centerLeft),
                      secondaryBackground: _buildDismissBg(Alignment.centerRight),
                      onDismissed: (_) => _deleteReminder(reminder),
                      child: _buildReminderCard(reminder, settings),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_reminder');
          if (result == true) {
            // If add screen returned true, ensure provider reloads (though addReminder should already update)
            await context.read<ReminderProvider>().loadReminders();
          }
        },
        backgroundColor: settings.isDarkmode ? Colors.black : Colors.white,
        elevation: 30.0,
        child: Icon(Icons.add, color: settings.isDarkmode ? Colors.white : Colors.black),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            _buildDrawerItem('Home', () => Navigator.pop(context)),
            _buildDrawerItem('Notes', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notes');
            }),
            _buildDrawerItem('Settings', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissBg(Alignment alignment) => Container(
        color: Colors.red,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      );

  Widget _buildReminderCard(Reminder reminder, SettingsProvider settings) {
    return Card(
      elevation: 10.0,
      color: settings.isDarkmode ? Colors.black : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          reminder.title,
          style: TextStyle(
            color: settings.isDarkmode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.content.isNotEmpty)
              Text(
                reminder.content,
                style: TextStyle(
                  color: settings.isDarkmode ? Colors.white : Colors.black,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'DateTime: ${reminder.dateTime}',
              style: TextStyle(
                fontSize: 12,
                color: settings.isDarkmode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () {
                NotificationService.showOngoingNotification(
                  title: reminder.title,
                  content: reminder.content.isNotEmpty ? reminder.content : 'Reminder is active',
                  dateTime: DateTime.parse(reminder.dateTime),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: NotificationService.cancelOngoingNotification,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReminder(reminder),
            ),
          ],
        ),
        onTap: () => _showReminderDialog(reminder),
      ),
    );
  }

  Widget _buildDrawerItem(String title, VoidCallback onTap) => ListTile(
        title: Text(title),
        onTap: onTap,
      );
}
