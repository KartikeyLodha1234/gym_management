import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Auth Methods ---
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  // --- Member Methods ---
  Future<void> addMember(Map<String, dynamic> memberData) async {
    if (memberData['imagePath'] != null) {
      File file = File(memberData['imagePath']);
      String fileName = 'members/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot snapshot = await _storage.ref().child(fileName).putFile(file);
      memberData['imagePath'] = await snapshot.ref.getDownloadURL();
    }
    await _db.collection('members').add(memberData);
  }

  Future<void> updateMember(String id, Map<String, dynamic> memberData) async {
    if (memberData['imagePath'] != null && !memberData['imagePath'].startsWith('http')) {
      File file = File(memberData['imagePath']);
      String fileName = 'members/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot snapshot = await _storage.ref().child(fileName).putFile(file);
      memberData['imagePath'] = await snapshot.ref.getDownloadURL();
    }
    await _db.collection('members').doc(id).update(memberData);
  }

  Future<void> deleteMember(String id) async {
    await _db.collection('members').doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getAllMembers() async {
    QuerySnapshot snapshot = await _db.collection('members').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }

  // --- Staff Methods ---
  Future<void> addStaff(Map<String, dynamic> staffData) async {
    await _db.collection('staff').add(staffData);
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    QuerySnapshot snapshot = await _db.collection('staff').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }

  // --- Payment Methods ---
  Future<void> addPayment(Map<String, dynamic> paymentData) async {
    await _db.collection('payments').add(paymentData);
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    QuerySnapshot snapshot = await _db.collection('payments').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }

  // --- Attendance Methods ---
  Future<void> addAttendance(Map<String, dynamic> attendanceData) async {
    await _db.collection('attendance').add(attendanceData);
  }

  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date) async {
    QuerySnapshot snapshot = await _db.collection('attendance').where('date', isEqualTo: date).get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }

  // --- Maintenance Methods ---
  Future<void> addMaintenance(Map<String, dynamic> data) async {
    await _db.collection('maintenance').add(data);
  }

  Future<List<Map<String, dynamic>>> getAllMaintenance() async {
    QuerySnapshot snapshot = await _db.collection('maintenance').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }
}
