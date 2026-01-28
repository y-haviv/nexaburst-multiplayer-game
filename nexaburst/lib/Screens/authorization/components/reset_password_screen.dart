// nexaburst/lib/Screens/authorization/component/reset_password_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexaburst/Screens/main_components/background_enter.dart';
import 'package:nexaburst/constants.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Background(
      child: SingleChildScrollView(
        child: Center(
          child: ResponsiveReset(),
        ),
      ),
    );
  }
}


class ResponsiveReset extends StatelessWidget {
  const ResponsiveReset({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final form = const ResetForm();
    return isDesktop
        ? Row(
            children: [
              const Spacer(),
              Expanded(flex: 5, child: form),
              const Spacer(),
            ],
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppNumbers.defaultPadding),
            child: form,
          );
  }
}

class ResetForm extends StatefulWidget {
  const ResetForm({super.key});

  @override
  _ResetFormState createState() => _ResetFormState();
}

class _ResetFormState extends State<ResetForm> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If an account exists, we’ve sent you a reset email.'),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Error. Try again.';
      if (e.code == 'invalid-email') msg = 'Invalid email address.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ← כפתור חזרה
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: AppNumbers.defaultPadding),
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppNumbers.defaultPadding * 2),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter email',
            filled: true,
            fillColor: AppColors.kPrimaryLightColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.email, color: AppColors.kPrimaryColor),
          ),
        ),
        const SizedBox(height: AppNumbers.defaultPadding * 1.5),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendReset,
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send Email'),
          ),
        ),
        const SizedBox(height: AppNumbers.defaultPadding),
      ],
    );
  }
}
