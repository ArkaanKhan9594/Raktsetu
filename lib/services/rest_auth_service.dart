import 'auth_service.dart';
import 'api_client.dart';

class RestAuthService implements AuthService {
  final ApiClient apiClient;
  String? _currentPhone;

  RestAuthService({required this.apiClient});

  @override
  Future<String> sendOtp(String phoneNumber) async {
    final res = await apiClient.post('/api/auth/send-otp', body: {'phone': phoneNumber});
    _currentPhone = phoneNumber;
    return (res is Map && res['verificationId'] != null)
        ? res['verificationId'].toString()
        : phoneNumber;
  }

  @override
  Future<bool> verifyOtp(String verificationId, String otp) async {
    final res = await apiClient.post('/api/auth/verify-otp', body: {
      'phone': _currentPhone ?? verificationId,
      'otp': otp,
    });
    if (res is Map && res['token'] != null) {
      apiClient.authToken = res['token'].toString();
      return true;
    }
    return false;
  }

  @override
  String? get currentPhone => _currentPhone;

  @override
  void signOut() {
    _currentPhone = null;
    apiClient.authToken = null;
  }
}
