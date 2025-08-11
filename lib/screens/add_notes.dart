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
  InterstitialAd? _interstitialAd;
  bool _isAdShowing = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.getInterstatialAdUnitId2,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (_) {
              setState(() => _isAdShowing = true);
            },
            onAdDismissedFullScreenContent: (ad) {
              setState(() => _isAdShowing = false);
              ad.dispose();
              _saveNote(); // Save after ad finishes
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              setState(() => _isAdShowing = false);
              _saveNote();
            },
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          print('Failed to load interstitial ad: ${err.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _saveNote() async {
    final note = Note(
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper().insertNote(note);
    Navigator.pop(context, true);
  }

  void _handleSave() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      _saveNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        // Prevent back press while ad is showing
        return !_isAdShowing;
      },
      child: Scaffold(
        backgroundColor: settings.backgroundColor,
        appBar: AppBar(
          backgroundColor: settings.appBarColor,
          iconTheme: IconThemeData(color: settings.fontColor),
          title: Text('Add Note', style: TextStyle(color: settings.fontColor)),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
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
                controller: _contentController,
                style: TextStyle(color: settings.fontColor, fontSize: 16),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Write your note...',
                  hintStyle: TextStyle(color: settings.fontColor),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.save),
                label: const Text("Save Note"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
