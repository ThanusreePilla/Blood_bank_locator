import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';
import 'details.dart';

class Nearby extends StatefulWidget {
  const Nearby({super.key});

  @override
  State<Nearby> createState() => _NearbyState();
}

class _NearbyState extends State<Nearby> {
  late Future<List<BloodBankRecord>> banksFuture;

  @override
  void initState() {
    super.initState();
    banksFuture = AppState.nearbyBanks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Blood Banks')),
      body: FutureBuilder<List<BloodBankRecord>>(
        future: banksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Could not load nearby blood banks.'));
          final banks = snapshot.data ?? [];
          if (banks.isEmpty) return const Center(child: Text('No blood banks available yet.'));
          return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
            for (final bank in banks) _NearbyCard(bank: bank),
          ]);
        },
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.bank});
  final BloodBankRecord bank;
  Color statusColor(int units) => units == 0 ? Colors.red.shade700 : units <= 5 ? Colors.orange.shade800 : Colors.green.shade700;
  @override
  Widget build(BuildContext context) {
    final group = AppState.bloodGroups.firstWhere((value) => bank.unitsFor(value) > 0, orElse: () => AppState.bloodGroups.first);
    final units = bank.unitsFor(group);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: bank.id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => Details(bank: bank, bloodGroup: group))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.local_hospital_outlined, size: 20, color: Color(0xFFB42332)), const SizedBox(width: 9), Expanded(child: Text(bank.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))), Text(bank.statusFor(group), style: TextStyle(color: statusColor(units), fontWeight: FontWeight.w700, fontSize: 12))]),
            const SizedBox(height: 7),
            Text('$group  •  $units units', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Text('${bank.address}, ${bank.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              bank.distanceKm.isFinite
                  ? '${bank.distanceKm.toStringAsFixed(1)} km away'
                  : 'Distance unavailable',
              style: const TextStyle(color: Color(0xFF7B8794), fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(children: [if (bank.verified) ...[Icon(Icons.verified, size: 14, color: Colors.green.shade700), const SizedBox(width: 4), const Text('Verified', style: TextStyle(color: Color(0xFF52606D), fontSize: 11)), const SizedBox(width: 10)], Expanded(child: Text('Updated ${bank.lastUpdated}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7B8794), fontSize: 11)))]),
            const SizedBox(height: 7),
            const Align(alignment: Alignment.centerRight, child: Text('View', style: TextStyle(color: Color(0xFFB42332), fontWeight: FontWeight.w700, fontSize: 12))),
          ]),
        ),
      ),
    );
  }
}
