import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/ad_helper.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/database_helper.dart';
import 'package:reminder/services/note_model.dart';
import 'package:reminder/services/noti_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  List<Note> allNotes = [];
  List<Note> filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  BannerAd? _bannerAd3;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterNotes);
    _initAds();
    _loadNotes();
  }

  void _initAds() {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId3,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd3 = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  Future<void> _loadNotes() async {
    final data = await DatabaseHelper().getNotes();
    setState(() {
      allNotes = data;
      filteredNotes = data; // Initially all notes shown
    });
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredNotes = allNotes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(query);
        final contentMatch = note.content.toLowerCase().contains(query);
        return titleMatch || contentMatch;
      }).toList();
    });
  }

  void _showEditDialog(Note note) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: settings.isDarkmode ? Colors.black : Colors.white,
          title: Text(
            'Edit Note',
            style: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: settings.isDarkmode ? Colors.white : Colors.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: settings.isDarkmode ? Colors.white : Colors.black),
                    ),
                  ),
                  style: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black),
                ),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: settings.isDarkmode ? Colors.white : Colors.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: settings.isDarkmode ? Colors.white : Colors.black),
                    ),
                  ),
                  maxLines: 1,
                  style: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.appBarColor,
                foregroundColor: settings.isDarkmode ? Colors.white : Colors.black,
              ),
              onPressed: () async {
                final updatedNote = Note(
                  id: note.id,
                  title: titleController.text,
                  content: contentController.text,
                  createdAt: note.createdAt,
                  isPinned: note.isPinned,
                );
                await DatabaseHelper().updateNote(updatedNote);
                Navigator.pop(context);
                _loadNotes();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(Note note) async {
    await DatabaseHelper().deleteNote(note.id!);
    _loadNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${note.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await DatabaseHelper().insertNote(note);
            _loadNotes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final bgColor = settings.backgroundColor;
    final textColor = settings.fontColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: settings.appBarColor,
        title: Text('My Notes', style: TextStyle(color: textColor)),
        centerTitle: true,
        iconTheme: IconThemeData(color: settings.fontColor),
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_bannerAd3 != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: _bannerAd3!.size.width.toDouble(),
                height: _bannerAd3!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd3!),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              bottom: (_bannerAd3 != null ? _bannerAd3!.size.height.toDouble() : 0) + 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: settings.fontColor),
                    hintText: 'Search Notes...',
                    hintStyle: TextStyle(color: textColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Dismissible(
                        key: Key(note.id.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          await _deleteNote(note);
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          color: settings.isDarkmode ? Colors.black : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              note.title,
                              style: TextStyle(
                                color: settings.isDarkmode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              note.content,
                              style: TextStyle(
                                color: settings.isDarkmode ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                    color: note.isPinned ? Colors.orange : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    final updatedNote = Note(
                                      id: note.id,
                                      title: note.title,
                                      content: note.content,
                                      createdAt: note.createdAt,
                                      isPinned: !note.isPinned,
                                    );
                                    await DatabaseHelper().updateNote(updatedNote);
                                    _loadNotes();

                                    if (updatedNote.isPinned) {
                                      NotificationService.showNoteNotification(
                                        title: updatedNote.title,
                                        content: updatedNote.content,
                                      );
                                    } else {
                                      NotificationService.cancelOngoingNotification();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteNote(note),
                                ),
                              ],
                            ),
                            onTap: () {
                              _showEditDialog(note);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_notes');
          if (result == true) {
            _loadNotes();
          }
        },
        backgroundColor: settings.isDarkmode ? Colors.black : Colors.white,
        child: Icon(Icons.add, color: settings.isDarkmode ? Colors.white : Colors.black),
      ),
    );
  }
}
