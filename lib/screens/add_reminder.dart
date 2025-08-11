import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/ad_helper.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/reminder_model.dart';
import 'package:reminder/services/reminder_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AddReminder extends StatefulWidget {
  const AddReminder({super.key});

  @override
  State<AddReminder> createState() => _AddReminderState();
}

class _AddReminderState extends State<AddReminder> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  InterstitialAd? _interstitialAd;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Reminder? _editingReminder;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.getInterstatialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) async {
              await _saveReminder();
            },
            onAdFailedToShowFullScreenContent: (_, __) async {
              await _saveReminder();
            },
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load ad: ${err.message}');
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Reminder? reminder =
        ModalRoute.of(context)?.settings.arguments as Reminder?;
    if (reminder != null && _titleController.text.isEmpty) {
      _editingReminder = reminder;
      _titleController.text = reminder.title;
      _notesController.text = reminder.content;
      _selectedDate = DateTime.parse(reminder.dateTime);
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveReminder() async {
    if (_titleController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final provider = context.read<ReminderProvider>();

    if (_editingReminder != null && _editingReminder!.id != null) {
      final updated = Reminder(
        id: _editingReminder!.id,
        title: _titleController.text,
        content: _notesController.text,
        dateTime: combinedDateTime.toIso8601String(),
      );
      await provider.updateReminder(updated);
    } else {
      final newReminder = Reminder(
        title: _titleController.text,
        content: _notesController.text,
        dateTime: combinedDateTime.toIso8601String(),
      );
      await provider.addReminder(newReminder);
    }

    Navigator.pop(context); // just pop, Home will auto-refresh via Provider
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final textColor = settings.fontColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: settings.appBarColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          _editingReminder != null ? 'Edit Reminder' : 'Add Reminder',
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
      ),
      backgroundColor: settings.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: textColor),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: textColor),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.calendar_today, color: textColor),
              title: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.toLocal()}'.split(' ')[0],
                style: TextStyle(color: textColor),
              ),
              onTap: _pickDate,
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: textColor),
              title: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : _selectedTime!.format(context),
                style: TextStyle(color: textColor),
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (_interstitialAd != null) {
                  _interstitialAd!.show();
                } else {
                  _saveReminder();
                }
              },
              icon: const Icon(Icons.save),
              label: Text(
                _editingReminder != null ? 'Update Reminder' : 'Save Reminder',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
