import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/ad_helper.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/note_model.dart';
import 'package:reminder/services/database_helper.dart';

class AddNotes extends StatefulWidget {
  const AddNotes({super.key});

  @override
  State<AddNotes> createState() => _AddNotesState();
}

class _AddNotesState extends State<AddNotes> {
  InterstitialAd? _interstitialAd2;

  @override
  void initState() {
    super.initState();
    InterstitialAd.load(
      adUnitId: AdHelper.getInterstatialAdUnitId2,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad){},
          );
          setState(() {
            _interstitialAd2 = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to loads ad: ${err.message}');
         }
      )
    );
  }

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
                  if (_interstitialAd2 != null) {
                    _interstitialAd2!.fullScreenContentCallback = FullScreenContentCallback(
                      onAdDismissedFullScreenContent: (ad) async{
                        ad.dispose();

                    Note note = Note(
                    title: titleController.text,
                    content: contentController.text,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  await DatabaseHelper().insertNote(note);
                  Navigator.pop(context, true);
                  },
                  onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  // If ad fails, still save the note
                  Note note = Note(
                  title: titleController.text,
                  content: contentController.text,
                  createdAt: DateTime.now().toIso8601String(),
                  );
                  DatabaseHelper().insertNote(note).then((_) {
                  Navigator.pop(context, true);
                  });
                  },
                  );

                  _interstitialAd2!.show();
                  } else {
                    Note note = Note(
                    title: titleController.text,
                    content: contentController.text,
                    createdAt: DateTime.now().toIso8601String(),
                      );
                    DatabaseHelper().insertNote(note).then((_) {
                    Navigator.pop(context, true);
                    });
                  }
                  print("Saving note...");
                  print("Title: ${titleController.text}");
                  print("Content: $contentController.text");

                 

                  
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