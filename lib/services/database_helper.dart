import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:reminder/services/reminder_model.dart';
import 'package:reminder/services/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if(_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'reminder.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate : _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2){
    await db.execute("ALTER TABLE notes ADD COLUMN isPinned INTEGER NOT NULL DEFAULT 0;");
    
  }
  
}
  Future _onCreate(Database db, int version) async{
    await db.execute('''
    CREATE TABLE reminders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title text,
    content TEXT,
    dateTime TEXT
    )
''');

    await db.execute('''
    CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    isPinned INTEGER DEFAULT 0
    )
''');


  }
  Future<int> insertReminder(Reminder reminder) async{
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<int> insertNote(Note note) async{
    try {
    final db = await database;
    return await db.insert(
      'notes', 
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    } catch(e) {
      print("Error inserting note: $e");
      return -1;
    }
  }

  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reminders');
    return List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));
  }

  Future<List<Note>> getNotes() async{
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    return List.generate(maps.length, (i) { 
      return Note.fromMap(maps[i]);
    });
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete('reminders' , where: 'id = ?' , whereArgs: [id]);
  }

  Future<int> deleteNote(int id) async{
    final db = await database;
    return await db.delete('notes' , where: 'id = ?' , whereArgs: [id]);
  }

  Future<int> updateReminder(Reminder updated) async {
    final db = await database;

    return await db.update(
      'reminders',
      updated.toMap(),
      where: 'id=?',
      whereArgs: [updated.id],
    );
  }

  Future<int> updateNote(Note note) async {
    final db = await database;

    return await db.update(
      'notes',
      note.toMap(),
      where: 'id=?',
      whereArgs: [note.id],
    );
  }
}