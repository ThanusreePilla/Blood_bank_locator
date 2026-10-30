import 'package:flutter/material.dart';
import 'seek_auth.dart';
import 'bank_auth.dart';


class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In / Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Choose how you want to use Blood Bank Locator.',
              style: TextStyle(fontSize: 15, color: Color(0xFF52606D)),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SeekAuth(),
    ),
  );
},
                  
              
                icon: const Icon(Icons.person),
                label: const Text('Continue as Seeker'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const BankAuth(),
    ),
  );
},
                icon: const Icon(Icons.local_hospital),
                label: const Text('Continue as Blood Bank'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}