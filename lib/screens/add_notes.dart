import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/note_model.dart';
import 'package:reminder/services/database_helper.dart';

class AddNotes extends StatelessWidget {
  const AddNotes({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.appBarColor,
        iconTheme: IconThemeData(color: settings.fontColor),
        title: Text(
          'Add Note',
          style: TextStyle(color: settings.fontColor),
        ),
      centerTitle: true,
      elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(
                color: settings.fontColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: settings.fontColor),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
                controller: contentController,
                style: TextStyle(color: settings.fontColor, fontSize: 16),
                maxLines: null,
                expands: false,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Write your note...',
                  hintStyle: TextStyle(
                    color: settings.fontColor
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  print("Saving note...");
                  print("Title: ${titleController.text}");
                  print("Content: $contentController.text");

                  Note note = Note(
                    title: titleController.text,
                    content: contentController.text,
                    createdAt: DateTime.now().toIso8601String(),
                  );

                  await DatabaseHelper().insertNote(note);
                  Navigator.pop(context, true);
                }, 
              icon: const Icon(Icons.save),
              label: const Text("Save Note"),
              style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            ),
          ],
        ),
        ),
      );
  }
}