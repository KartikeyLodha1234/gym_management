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
      version: 13, // Incremented for Admin Settings
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createPaymentsTable(db);
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE members ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE members ADD COLUMN password TEXT');
      await db.execute('ALTER TABLE members ADD COLUMN dob TEXT');
    }
    if (oldVersion < 4) await _createEventsTable(db);
    if (oldVersion < 5) await _createStaffTable(db);
    if (oldVersion < 6) await db.execute('ALTER TABLE staff ADD COLUMN imagePath TEXT');
    if (oldVersion < 7) await _createAttendanceTable(db);
    if (oldVersion < 8) {
      await _createMaintenanceTable(db);
      await _createPlansTable(db);
    }
    if (oldVersion < 10) {
      await db.execute('DROP TABLE IF EXISTS maintenance');
      await _createMaintenanceTable(db);
      await _createInventoryTable(db);
    }
    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE attendance ADD COLUMN checkOutTime TEXT');
        await db.execute('ALTER TABLE attendance ADD COLUMN userType TEXT DEFAULT "Member"');
      } catch (e) {}
    }
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE attendance ADD COLUMN checkInPhoto TEXT');
        await db.execute('ALTER TABLE attendance ADD COLUMN checkOutPhoto TEXT');
        await db.execute('ALTER TABLE attendance ADD COLUMN checkInLat REAL');
        await db.execute('ALTER TABLE attendance ADD COLUMN checkInLong REAL');
        await db.execute('ALTER TABLE attendance ADD COLUMN checkOutLat REAL');
        await db.execute('ALTER TABLE attendance ADD COLUMN checkOutLong REAL');
      } catch (e) {}
    }
    if (oldVersion < 13) {
      await db.execute('CREATE TABLE admin_settings (key TEXT PRIMARY KEY, value TEXT)');
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
    await _createMaintenanceTable(db);
    await _createPlansTable(db);
    await _createInventoryTable(db);
    await db.execute('CREATE TABLE admin_settings (key TEXT PRIMARY KEY, value TEXT)');
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
        checkOutTime TEXT,
        userType TEXT DEFAULT "Member",
        status TEXT NOT NULL,
        checkInPhoto TEXT,
        checkOutPhoto TEXT,
        checkInLat REAL,
        checkInLong REAL,
        checkOutLat REAL,
        checkOutLong REAL
      )
    ''');
  }

  Future _createMaintenanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentName TEXT NOT NULL,
        category TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        status TEXT NOT NULL,
        reportedBy TEXT,
        repairedBy TEXT,
        date TEXT NOT NULL,
        nextServiceDate TEXT,
        cost REAL,
        remarks TEXT,
        partsUsed TEXT
      )
    ''');
  }

  Future _createPlansTable(Database db) async {
    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price TEXT NOT NULL,
        duration TEXT NOT NULL,
        features TEXT,
        color INTEGER
      )
    ''');
  }

  Future _createInventoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT
      )
    ''');
  }

  // --- CRUD Methods ---
  
  // Members
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
    return await db.update('members', member, where: 'id = ?', whereArgs: [member['id']]);
  }
  Future<int> deleteMember(int id) async {
    final db = await instance.database;
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // Staff
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
    return await db.update('staff', staff, where: 'id = ?', whereArgs: [staff['id']]);
  }
  Future<int> deleteStaff(int id) async {
    final db = await instance.database;
    return await db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  // Payments
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await instance.database;
    return await db.insert('payments', payment);
  }
  Future<List<Map<String, dynamic>>> queryAllPayments() async {
    final db = await instance.database;
    return await db.query('payments');
  }
  Future<int> deletePayment(int id) async {
    final db = await instance.database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // Events
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

  // Attendance
  Future<int> insertAttendance(Map<String, dynamic> attendance) async {
    final db = await instance.database;
    return await db.insert('attendance', attendance);
  }
  Future<List<Map<String, dynamic>>> queryAttendanceByDate(String date) async {
    final db = await instance.database;
    return await db.query('attendance', where: 'date = ? AND userType = "Member"', whereArgs: [date]);
  }
  Future<List<Map<String, dynamic>>> queryStaffAttendanceByDate(String date) async {
    final db = await instance.database;
    return await db.query('attendance', where: 'date = ? AND userType = "Staff"', whereArgs: [date]);
  }
  Future<List<Map<String, dynamic>>> queryAllAttendance() async {
    final db = await instance.database;
    return await db.query('attendance', orderBy: 'date DESC, time DESC');
  }
  Future<int> updateAttendance(int id, Map<String, dynamic> values) async {
    final db = await instance.database;
    return await db.update('attendance', values, where: 'id = ?', whereArgs: [id]);
  }
  Future<int> updateCheckOutTime(int id, String checkOutTime) async {
    final db = await instance.database;
    return await db.update('attendance', {'checkOutTime': checkOutTime}, where: 'id = ?', whereArgs: [id]);
  }
  Future<int> deleteAttendance(int id) async {
    final db = await instance.database;
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  // Maintenance
  Future<int> insertMaintenance(Map<String, dynamic> record) async {
    final db = await instance.database;
    return await db.insert('maintenance', record);
  }
  Future<List<Map<String, dynamic>>> queryAllMaintenance() async {
    final db = await instance.database;
    return await db.query('maintenance', orderBy: 'date DESC');
  }
  Future<int> updateMaintenance(Map<String, dynamic> record) async {
    final db = await instance.database;
    return await db.update('maintenance', record, where: 'id = ?', whereArgs: [record['id']]);
  }
  Future<int> deleteMaintenance(int id) async {
    final db = await instance.database;
    return await db.delete('maintenance', where: 'id = ?', whereArgs: [id]);
  }

  // Plans
  Future<int> insertPlan(Map<String, dynamic> plan) async {
    final db = await instance.database;
    return await db.insert('plans', plan);
  }
  Future<List<Map<String, dynamic>>> queryAllPlans() async {
    final db = await instance.database;
    return await db.query('plans');
  }
  Future<int> updatePlan(Map<String, dynamic> plan) async {
    final db = await instance.database;
    return await db.update('plans', plan, where: 'id = ?', whereArgs: [plan['id']]);
  }
  Future<int> deletePlan(int id) async {
    final db = await instance.database;
    return await db.delete('plans', where: 'id = ?', whereArgs: [id]);
  }

  // Admin Settings
  Future<void> saveAdminSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('admin_settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getAdminSetting(String key) async {
    final db = await instance.database;
    final res = await db.query('admin_settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) return res.first['value'] as String;
    return null;
  }
}
