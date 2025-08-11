import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'reminder_model.dart';

class ReminderProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];

  List<Reminder> get reminders => _reminders;

  Future<void> loadReminders() async {
    _reminders = await DatabaseHelper().getReminders();
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    await DatabaseHelper().insertReminder(reminder);
    await loadReminders();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await DatabaseHelper().updateReminder(reminder);
    await loadReminders();
  }

  Future<void> deleteReminder(Reminder reminder) async {
    await DatabaseHelper().deleteReminder(reminder.id!);
    await loadReminders();
  }
}
