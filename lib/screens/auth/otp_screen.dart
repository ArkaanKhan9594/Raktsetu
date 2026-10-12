import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../home/home_shell.dart';
import 'profile_setup_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  const OtpScreen({super.key, required this.phone, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _verifying = false;

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() => _verifying = true);
    final appState = context.read<AppState>();
    final ok = await appState.auth.verifyOtp(widget.verificationId, _otp);
    setState(() => _verifying = false);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect OTP. Try 123456 for demo.')),
      );
      return;
    }

    try {
      await appState.loginWithPhone(widget.phone);
    } catch (_) {}
    if (!mounted) return;

    if (appState.currentDonor == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfileSetupScreen(phone: widget.phone)),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 6-digit code sent to +91 ${widget.phone}',
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (v) => setState(() => _otp = v),
              onCompleted: (_) => _verify(),
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 48,
                fieldWidth: 42,
                activeColor: const Color(0xFF1B3A6B),
                selectedColor: const Color(0xFFB3122E),
                inactiveColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Demo tip: use 123456 to bypass OTP verification.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
                child: _verifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify & Continue', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
