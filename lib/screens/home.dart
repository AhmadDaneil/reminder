import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/ad_helper.dart';
import 'package:reminder/services/noti_service.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/reminder_model.dart';
import 'package:reminder/services/database_helper.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Reminder> reminders = [];
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final data = await DatabaseHelper().getReminders();
    setState(() {
      reminders = data;
    });
  }

  void _showReminderDialog(Reminder reminder) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkmode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(reminder.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.content.isNotEmpty)
              Text('Notes: ${reminder.content}'),
            const SizedBox(height: 8),
            Text('DateTime: ${reminder.dateTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final result = await Navigator.pushNamed(
                context,
                '/add_reminder',
                arguments: reminder,
              );
              if (result == true) {
                _loadReminders();
              }
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await DatabaseHelper().deleteReminder(reminder.id!);
    _loadReminders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reminder.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await DatabaseHelper().insertReminder(reminder);
            _loadReminders();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

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
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          reminders.isEmpty
              ? Center(
                  child: Text(
                    'No Reminders Yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                      color:
                          Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: (_bannerAd != null
                            ? _bannerAd!.size.height.toDouble()
                            : 0) +
                        16, // 👈 Push list down below banner
                    left: 16,
                    right: 16,
                  ),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];

                    return Dismissible(
                      key: Key(reminder.id.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteReminder(reminder);
                      },
                      child: Card(
                        elevation: 10.0,
                        color: settings.isDarkmode
                            ? Colors.black
                            : Colors.white,
                        margin:
                            const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            reminder.title,
                            style: TextStyle(
                              color: settings.isDarkmode
                                  ? Colors.white
                                  : Colors.black,
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
                                    color: settings.isDarkmode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'DateTime: ${reminder.dateTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: settings.isDarkmode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow,
                                    color: Colors.green),
                                onPressed: () {
                                  NotificationService
                                      .showOngoingNotification(
                                    title: reminder.title,
                                    content: reminder.content.isNotEmpty
                                        ? reminder.content
                                        : 'Reminder is active',
                                    dateTime: DateTime.parse(
                                        reminder.dateTime),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.stop,
                                    color: Colors.red),
                                onPressed: () {
                                  NotificationService
                                      .cancelOngoingNotification();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  _deleteReminder(reminder);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _showReminderDialog(reminder);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, '/add_reminder');
          if (result == true) {
            _loadReminders();
          }
        },
        backgroundColor:
            settings.isDarkmode ? Colors.black : Colors.white,
        elevation: 30.0,
        child: Icon(Icons.add,
            color: settings.isDarkmode ? Colors.white : Colors.black),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: const Text('Home'),
              onTap: () async {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Notes'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notes');
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
