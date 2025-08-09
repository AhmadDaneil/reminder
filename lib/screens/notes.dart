import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:reminder/services/database_helper.dart';
import 'package:reminder/services/note_model.dart';
import 'package:reminder/services/noti_service.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async{
    final data = await DatabaseHelper().getNotes();
    for (var note in data) {
      print("Note: ${note.title}, ${note.content}, ${note.createdAt}");
    }
    setState(() {
      notes = data;
    });
  }

  void _showEditDialog(Note note) {
    final settings = Provider.of<SettingsProvider>(context, listen:false);
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
            child: Column(children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: settings.isDarkmode ? Colors.white : Colors.black),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: settings.isDarkmode ? Colors.white : Colors.black),
                ),
                ),
              ),
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: 'Content', labelStyle: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black),
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
              style: ElevatedButton.styleFrom(backgroundColor: settings.appBarColor, foregroundColor: settings.isDarkmode ? Colors.white : Colors.black),
              onPressed: () async{
                final updatedNote = Note(
                  id: note.id,
                  title: titleController.text,
                  content: contentController.text,
                  createdAt: note.createdAt,
                );
                await DatabaseHelper().updateNote(updatedNote);
                Navigator.pop(context);
                _loadNotes();
              }, 
              child: const Text('Save'),
              ),
          ],
        );
      }
    );
  }

  Future<void> _deleteNote(Note note) async{
    await DatabaseHelper().deleteNote(note.id!);
    _loadNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${note.title} deleted'),
      action: SnackBarAction(label: 'Undo', 
      onPressed: () async {
        await DatabaseHelper().insertNote(note);
        _loadNotes();
      }
      ),
      )
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
        title: Text(
          'My Notes',
          style: TextStyle(color: textColor),
          ),
        centerTitle: true,
        iconTheme: IconThemeData(color: settings.fontColor),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: settings.fontColor),
                hintText: 'Search Notes...',
                hintStyle: TextStyle(color: textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];

                  return Dismissible(
                    key: Key(note.id.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await _deleteNote(note);
                    }, 
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                    color: settings.isDarkmode ? Colors.black : Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        notes[index].title,
                        style: TextStyle(color: settings.isDarkmode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        notes[index].content,
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
                        // Show pinned note notification
                        NotificationService.showOngoingNotification(
                        title: updatedNote.title,
                        content: updatedNote.content,
                        dateTime: DateTime.parse(updatedNote.createdAt),
                        );
                        } else {
                        // Remove notification
                        NotificationService.cancelOngoingNotification();
                        }
                      },
                    ),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteNote(note);
                      },
                    ),
                  ],
                ),
                onTap: (){
                  _showEditDialog(notes[index]);
                },
              ),
            )
          );
        }
      ),
      ),
      ]
      )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          final result = await Navigator.pushNamed(context, '/add_notes');
          if (result == true){
            _loadNotes();
          }
        },
        backgroundColor: settings.isDarkmode ?Colors.black : Colors.white,
        child: Icon(Icons.add, color: settings.isDarkmode ? Colors.white : Colors.black),
        ),
    );
  }
}