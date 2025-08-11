import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/screens/home.dart';
import 'package:reminder/services/ad_helper.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/database_helper.dart';
import 'package:reminder/services/reminder_model.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AddReminder extends StatefulWidget {
  const AddReminder({super.key});

  @override
  State<AddReminder> createState() => _AddReminderState();
}

class _AddReminderState extends State<AddReminder> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  InterstitialAd ? _interstitialAd;
  
  @override
  void initState () {
    super.initState();
    InterstitialAd.load(
      adUnitId: AdHelper.getInterstatialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) async{
              await _saveReminder();
            },
            onAdFailedToShowFullScreenContent: (ad, error) async {
              await _saveReminder();
            }
          );
          setState(() {
            _interstitialAd = ad;
          });
        },
         onAdFailedToLoad: (err) {
          print('Failed to loads ad: ${err.message}');
         }),);
  }
  

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Reminder? reminder =
        ModalRoute.of(context)?.settings.arguments as Reminder?;
    if (reminder != null && _titleController.text.isEmpty) {
      _titleController.text = reminder.title;
      _notesController.text = reminder.content;
      _selectedDate = DateTime.parse(reminder.dateTime);
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    final DateTime combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final reminder = Reminder(
      title: _titleController.text,
      content: _notesController.text,
      dateTime: combinedDateTime.toIso8601String(),
    );

    final existing =
        ModalRoute.of(context)?.settings.arguments as Reminder?;
    if (existing != null && existing.id != null) {
      final updated = Reminder(
        id: existing.id,
        title: reminder.title,
        content: reminder.content,
        dateTime: reminder.dateTime,
      );
      await DatabaseHelper().updateReminder(updated);
    } else {
      await DatabaseHelper().insertReminder(reminder);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final textColor = settings.fontColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: settings.appBarColor,
        iconTheme: IconThemeData(color: settings.fontColor),
        title: Text('Add Reminder', style: TextStyle(color: settings.fontColor)),
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
                  labelText: 'Title', labelStyle: TextStyle(color: textColor)),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: textColor)),
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
              onPressed: () async {
                if(_interstitialAd !=null){
                _interstitialAd!.show();
                } else {
                  _saveReminder();
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Reminder'),
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
