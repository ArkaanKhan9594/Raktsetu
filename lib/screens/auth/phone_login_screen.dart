import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }
    setState(() => _sending = true);
    final appState = context.read<AppState>();
    final verificationId = await appState.auth.sendOtp(phone);
    setState(() => _sending = false);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtpScreen(phone: phone, verificationId: verificationId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bloodtype, size: 64, color: Color(0xFFB3122E)),
              const SizedBox(height: 16),
              const Text('RaktSetu', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B3A6B))),
              const Text('Every donor, every drop, connected.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              const Text('Enter your mobile number', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  prefixText: '+91  ',
                  hintText: '9XXXXXXXXX',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
                  child: _sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send OTP', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
