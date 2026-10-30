import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';
import 'bank_profile.dart';
import 'bank_requests.dart';
import 'stock.dart';
import 'welcome.dart';

class BankHome extends StatefulWidget {
  const BankHome({super.key});
  @override
  State<BankHome> createState() => _BankHomeState();
}

class _BankHomeState extends State<BankHome> {
  late Future<List<BloodRequestRecord>> requestsFuture;

  @override
  void initState() {
    super.initState();
    requestsFuture = _loadDashboardData();
  }

  Future<List<BloodRequestRecord>> _loadDashboardData() async {
    await AppState.refreshBankSession();
    return AppState.bankRequests();
  }

  void refresh() => setState(() => requestsFuture = _loadDashboardData());
  String statusFor(int units) => units == 0 ? 'Out of Stock' : units <= 5 ? 'Low Stock' : 'Available';
  Color statusColor(int units) => units == 0 ? Colors.red : units <= 5 ? Colors.orange.shade800 : Colors.green.shade700;

  Future<void> logout() async {
    await AppState.resetSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Welcome()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bank = AppState.session.bank;
    if (bank == null) return const Scaffold(body: Center(child: Text('Bank session expired. Please sign in again.')));
    final totalUnits = bank.stock.values.fold<int>(0, (sum, units) => sum + units);
    final availableGroups = bank.stock.values.where((units) => units > 0).length;
    final lowStockCount = bank.stock.values.where((units) => units > 0 && units <= 5).length;
    final hasStock = totalUnits > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Bank Dashboard'), actions: [
        IconButton(tooltip: 'View profile', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankProfile())), icon: const Icon(Icons.account_circle_outlined)),
        IconButton(tooltip: 'Log out', onPressed: logout, icon: const Icon(Icons.logout)),
      ]),
      body: FutureBuilder<List<BloodRequestRecord>>(
        future: requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: OutlinedButton(onPressed: refresh, child: const Text('Retry')));
          final pending = (snapshot.data ?? []).where((request) => request.status == 'Pending').length;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [Expanded(child: Text(bank.name, style: Theme.of(context).textTheme.headlineSmall)), Icon(bank.verified ? Icons.verified : Icons.info_outline, color: bank.verified ? Colors.green : Colors.orange)]),
            const SizedBox(height: 6),
            const Text('Welcome back. Keep your blood stock up to date.'),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Current status', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(hasStock ? 'Stock available for requests' : 'No stock currently available', style: TextStyle(color: hasStock ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600))]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: _SummaryCard(icon: Icons.inventory_2_outlined, label: 'Total units', value: '$totalUnits')), const SizedBox(width: 8), Expanded(child: _SummaryCard(icon: Icons.water_drop_outlined, label: 'Groups available', value: '$availableGroups / 8')), const SizedBox(width: 8), Expanded(child: _SummaryCard(icon: Icons.warning_amber_outlined, label: 'Low stock', value: '$lowStockCount'))]),
            const SizedBox(height: 12),
            Card(child: ListTile(leading: const Icon(Icons.pending_actions, color: Color(0xFFB42332)), title: const Text('Pending requests', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('$pending requests need review'), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const BankRequests())); if (mounted) refresh(); })),
            const SizedBox(height: 28),
            Text('Blood stock overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Column(children: [
                for (final entry in bank.stock.entries)
                  ListTile(leading: const Icon(Icons.bloodtype_outlined), title: Text(entry.key), subtitle: Text('${entry.value} units'), trailing: Text(statusFor(entry.value), style: TextStyle(color: statusColor(entry.value), fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 28),
            Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(height: 52, child: ElevatedButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const Stock())); if (mounted) refresh(); }, icon: const Icon(Icons.edit_note), label: const Text('Manage Blood Stock'))),
            const SizedBox(height: 12),
            SizedBox(height: 52, child: OutlinedButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const BankRequests())); if (mounted) refresh(); }, icon: const Icon(Icons.inbox_outlined), label: const Text('Manage Requests'))),
            const SizedBox(height: 12),
            SizedBox(height: 52, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankProfile())), icon: const Icon(Icons.business_outlined), label: const Text('Blood Bank Profile'))),
          ]);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label, maxLines: 2)])));
}
