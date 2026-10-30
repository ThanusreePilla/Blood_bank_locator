import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'welcome.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Future<void> editProfile() async {
    final nameController = TextEditingController(text: AppState.seekerName);
    final emailController = TextEditingController(text: AppState.seekerEmail);
    final phoneController = TextEditingController(text: AppState.seekerPhone);
    Future<dynamic>? dialogCompleted;

    final updatedProfile = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        dialogCompleted = ModalRoute.of(context)?.completed;
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, [
                nameController.text.trim(),
                emailController.text.trim(),
                phoneController.text.trim(),
              ]),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    await dialogCompleted;
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    if (updatedProfile == null || updatedProfile.any((value) => value.isEmpty)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete every profile field.')));
      return;
    }
    if (!AppState.isValidEmail(updatedProfile[1])) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address.')));
      return;
    }
    try {
      await AppState.updateSeekerProfile(name: updatedProfile[0], email: updatedProfile[1], phone: updatedProfile[2]);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That email address is already in use.')));
    }
  }

  Future<void> logout() async {
    await AppState.resetSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Welcome()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppState.session.user?.role != 'seeker') {
      return const Scaffold(body: Center(child: Text('Seeker session expired.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seeker Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.person_outline, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppState.seekerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(AppState.seekerEmail),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone number'),
                  subtitle: Text(AppState.seekerPhone),
                ),
                const ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text('Account type'),
                  subtitle: Text('Blood Seeker'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}