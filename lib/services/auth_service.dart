import 'dart:async';
import 'dart:math';

/// Abstraction so the real Firebase Phone-Auth implementation can be swapped
/// in later without touching any UI code. See README > Firebase Integration.
abstract class AuthService {
  Future<String> sendOtp(String phoneNumber); // returns a verificationId
  Future<bool> verifyOtp(String verificationId, String otp);
  String? get currentPhone;
  void signOut();
}

/// Local mock implementation — generates and "sends" (prints) a 6-digit OTP.
/// Perfect for demoing without a Firebase project configured.
class MockAuthService implements AuthService {
  String? _pendingOtp;
  String? _pendingPhone;
  String? _currentPhone;

  @override
  Future<String> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _pendingPhone = phoneNumber;
    _pendingOtp = (100000 + Random().nextInt(899999)).toString();
    // ignore: avoid_print
    print('[MockAuthService] OTP for $phoneNumber is $_pendingOtp');
    return 'mock-verification-id';
  }

  @override
  Future<bool> verifyOtp(String verificationId, String otp) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final ok = otp == _pendingOtp || otp == '123456'; // 123456 = demo bypass
    if (ok) _currentPhone = _pendingPhone;
    return ok;
  }

  @override
  String? get currentPhone => _currentPhone;

  @override
  void signOut() => _currentPhone = null;
}
