import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/saved_account_suggestions.dart';
import 'seek_home.dart';

class SeekAuth extends StatefulWidget {
  const SeekAuth({super.key});

  @override
  State<SeekAuth> createState() => _SeekAuthState();
}

class _SeekAuthState extends State<SeekAuth> {
  bool login = true;
  bool busy = false;
  bool passwordVisible = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  List<String> savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final accounts = await AppState.savedAccounts(role: 'seeker');
      if (!mounted) return;
      setState(() => savedAccounts = accounts);
      if (emailController.text.trim().isEmpty && accounts.isNotEmpty) {
        emailController.text = accounts.first;
      }
    } catch (_) {
      // Keep the login form usable if local suggestions are unavailable.
    }
  }

  Future<void> _removeSavedAccount(String email) async {
    try {
      await AppState.removeSavedAccount(email: email, role: 'seeker');
      if (!mounted) return;
      setState(() => savedAccounts.remove(email));
      if (emailController.text.trim().toLowerCase() == email.toLowerCase()) {
        emailController.clear();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove the saved account.')),
        );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || (!login && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all required details.')),
      );
      return;
    }
    if (!AppState.isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }
    if (!login && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use a password with at least 6 characters.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    String? error;
    try {
      error = login
          ? (await AppState.login(
                      email: email,
                      password: password,
                      role: 'seeker',
                    ) ==
                    null
                ? 'Invalid email or password.'
                : null)
          : await AppState.registerSeeker(
              name: name,
              email: email,
              password: password,
            );
    } catch (_) {
      error = 'Could not access the local database. Please try again.';
    }
    if (!mounted) return;
    setState(() => busy = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SeekHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(login ? 'Seeker Login' : 'Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),

            Text(
              login ? 'Welcome back' : 'Create your account',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              login
                  ? 'Sign in to manage your blood requests.'
                  : 'Register to manage requests and saved blood banks.',
              style: const TextStyle(fontSize: 15, color: Color(0xFF52606D)),
            ),

            const SizedBox(height: 30),

            if (!login) ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            if (login && savedAccounts.isNotEmpty) ...[
              const SizedBox(height: 10),
              SavedAccountSuggestions(
                accounts: savedAccounts,
                onSelect: (email) => setState(() {
                  emailController.text = email;
                  emailController.selection = TextSelection.collapsed(
                    offset: email.length,
                  );
                }),
                onRemove: _removeSavedAccount,
              ),
            ],

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: !passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => passwordVisible = !passwordVisible);
                  },
                  icon: Icon(
                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: busy ? null : authenticate,
                child: Text(
                  busy
                      ? 'Please wait...'
                      : login
                      ? 'Sign In'
                      : 'Create Account',
                ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    login = !login;
                  });
                },
                child: Text(
                  login
                      ? 'New user? Create an account'
                      : 'Already have an account? Sign in',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
