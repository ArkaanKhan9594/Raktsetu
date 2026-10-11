import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

/// Real Firebase Phone Authentication implementation.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  String? _currentPhone;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();
    _currentPhone = phoneNumber;

    // Ensure phone number has country code format
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete('auto-verified');
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  @override
  Future<bool> verifyOtp(String verificationId, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user != null;
    } catch (e) {
      return false;
    }
  }

  @override
  String? get currentPhone => _currentPhone ?? _auth.currentUser?.phoneNumber;

  @override
  void signOut() {
    _currentPhone = null;
    _auth.signOut();
  }
}
