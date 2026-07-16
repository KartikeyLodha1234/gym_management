import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Auth Methods ---
  Future<User?> signIn(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  // --- Member Methods ---
  Future<void> addMember(Map<String, dynamic> memberData, File? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      // Upload image to Firebase Storage
      String fileName = 'members/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot snapshot = await _storage.ref().child(fileName).putFile(imageFile);
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    memberData['imagePath'] = imageUrl; // Store online URL instead of local path
    await _db.collection('members').add(memberData);
  }

  Stream<List<Map<String, dynamic>>> getMembers() {
    return _db.collection('members').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList());
  }

  // --- Payment Methods ---
  Future<void> addPayment(Map<String, dynamic> paymentData) async {
    await _db.collection('payments').add(paymentData);
  }

  // --- Maintenance Methods ---
  Future<void> addMaintenance(Map<String, dynamic> data) async {
    await _db.collection('maintenance').add(data);
  }
}
