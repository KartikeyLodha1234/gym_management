import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Incremented version for events table
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPaymentsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE members ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE members ADD COLUMN password TEXT');
      await db.execute('ALTER TABLE members ADD COLUMN dob TEXT');
    }
    if (oldVersion < 4) {
      await _createEventsTable(db);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        emergency TEXT,
        gender TEXT,
        age INTEGER,
        dob TEXT,
        email TEXT,
        password TEXT,
        joinDate TEXT,
        plan TEXT,
        price TEXT,
        expiryDate TEXT,
        trainer TEXT,
        imagePath TEXT,
        status TEXT
      )
    ''');
    await _createPaymentsTable(db);
    await _createEventsTable(db);
  }

  Future _createPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memberId INTEGER,
        memberName TEXT,
        plan TEXT,
        price REAL,
        discount REAL,
        tax REAL,
        totalPayable REAL,
        paymentMethod TEXT,
        paymentDate TEXT,
        status TEXT
      )
    ''');
  }

  Future _createEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        schedule TEXT,
        description TEXT
      )
    ''');
  }

  // Member Methods
  Future<int> insertMember(Map<String, dynamic> member) async {
    final db = await instance.database;
    return await db.insert('members', member);
  }

  Future<List<Map<String, dynamic>>> queryAllMembers() async {
    final db = await instance.database;
    return await db.query('members');
  }

  Future<int> updateMember(Map<String, dynamic> member) async {
    final db = await instance.database;
    int id = member['id'];
    return await db.update(
      'members',
      member,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await instance.database;
    return await db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Payment Methods
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await instance.database;
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> queryAllPayments() async {
    final db = await instance.database;
    return await db.query('payments');
  }

  // Event Methods
  Future<int> insertEvent(Map<String, dynamic> event) async {
    final db = await instance.database;
    return await db.insert('events', event);
  }

  Future<List<Map<String, dynamic>>> queryAllEvents() async {
    final db = await instance.database;
    return await db.query('events', orderBy: 'date DESC');
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
