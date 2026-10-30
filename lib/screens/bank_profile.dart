import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';
import 'welcome.dart';

class BankProfile extends StatefulWidget {
  const BankProfile({super.key});
  @override
  State<BankProfile> createState() => _BankProfileState();
}

class _BankProfileState extends State<BankProfile> {
  BloodBankRecord? get bank => AppState.session.bank;
  Future<void> logout() async { await AppState.resetSession(); if (!mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Welcome()), (_) => false); }

  Future<void> editProfile() async {
    final current = bank;
    if (current == null) return;
    final nameController = TextEditingController(text: current.name);
    final addressController = TextEditingController(text: current.address);
    final cityController = TextEditingController(text: current.location);
    final phoneController = TextEditingController(text: current.contact);
    final emailController = TextEditingController(text: current.email);
    Future<dynamic>? dialogCompleted;
    final values = await showDialog<List<String>>(context: context, builder: (context) {
      dialogCompleted = ModalRoute.of(context)?.completed;
      return AlertDialog(title: const Text('Edit Bank Profile'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Bank name')), const SizedBox(height: 12), TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')), const SizedBox(height: 12), TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')), const SizedBox(height: 12), TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')), const SizedBox(height: 12), TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, [nameController.text.trim(), addressController.text.trim(), cityController.text.trim(), phoneController.text.trim(), emailController.text.trim()]), child: const Text('Save'))]);
    });
    await dialogCompleted;
    nameController.dispose(); addressController.dispose(); cityController.dispose(); phoneController.dispose(); emailController.dispose();
    if (!mounted || values == null) return;
    if (values.any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete every bank profile field.')));
      return;
    }
    if (!AppState.isValidEmail(values[4])) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address.'))); return; }
    try {
      await AppState.updateBankProfile(name: values[0], address: values[1], city: values[2], phone: values[3], email: values[4]);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank profile updated successfully.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That email address is already in use.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = bank;
    final user = AppState.session.user;
    if (current == null || user == null || user.role != 'bank') return const Scaffold(body: Center(child: Text('Bank session expired.')));
    return Scaffold(appBar: AppBar(title: const Text('Blood Bank Profile')), body: ListView(padding: const EdgeInsets.all(20), children: [Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [CircleAvatar(radius: 30, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.local_hospital_outlined, size: 30)), const SizedBox(width: 16), Expanded(child: Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))]))), const SizedBox(height: 16), Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bank information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.location_on_outlined), title: const Text('Address'), subtitle: Text('${current.address}, ${current.location}')), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.phone_outlined), title: const Text('Contact number'), subtitle: Text(current.contact)), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(user.email)), const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.business_outlined), title: Text('Account type'), subtitle: Text('Blood Bank')), ListTile(contentPadding: EdgeInsets.zero, leading: Icon(current.verified ? Icons.verified_outlined : Icons.info_outline), title: const Text('Verification status'), subtitle: Text(current.verified ? 'Verified blood bank' : 'Verification pending')), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.schedule_outlined), title: const Text('Opening hours'), subtitle: Text(current.openingHours))]))), const SizedBox(height: 24), SizedBox(height: 52, child: ElevatedButton.icon(onPressed: editProfile, icon: const Icon(Icons.edit_outlined), label: const Text('Edit Profile'))), const SizedBox(height: 12), OutlinedButton.icon(onPressed: logout, icon: const Icon(Icons.logout), label: const Text('Logout'))]));
  }
}
