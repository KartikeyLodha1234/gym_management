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
      version: 7, // Incremented for attendance table
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
    if (oldVersion < 5) {
      await _createStaffTable(db);
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE staff ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 7) {
      await _createAttendanceTable(db);
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
    await _createStaffTable(db);
    await _createAttendanceTable(db);
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

  Future _createStaffTable(Database db) async {
    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        phone TEXT,
        joinDate TEXT,
        imagePath TEXT
      )
    ''');
  }

  Future _createAttendanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memberId INTEGER NOT NULL,
        memberName TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL
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

  // Staff Methods
  Future<int> insertStaff(Map<String, dynamic> staff) async {
    final db = await instance.database;
    return await db.insert('staff', staff);
  }

  Future<List<Map<String, dynamic>>> queryAllStaff() async {
    final db = await instance.database;
    return await db.query('staff');
  }

  Future<int> updateStaff(Map<String, dynamic> staff) async {
    final db = await instance.database;
    int id = staff['id'];
    return await db.update(
      'staff',
      staff,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteStaff(int id) async {
    final db = await instance.database;
    return await db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  // Attendance Methods
  Future<int> insertAttendance(Map<String, dynamic> attendance) async {
    final db = await instance.database;
    return await db.insert('attendance', attendance);
  }

  Future<List<Map<String, dynamic>>> queryAttendanceByDate(String date) async {
    final db = await instance.database;
    return await db.query('attendance', where: 'date = ?', whereArgs: [date]);
  }

  Future<List<Map<String, dynamic>>> queryAllAttendance() async {
    final db = await instance.database;
    return await db.query('attendance', orderBy: 'date DESC, time DESC');
  }

  Future<int> deleteAttendance(int id) async {
    final db = await instance.database;
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }
}
