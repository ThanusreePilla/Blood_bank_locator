import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';

class BankRequests extends StatefulWidget {
  const BankRequests({super.key});
  @override
  State<BankRequests> createState() => _BankRequestsState();
}

class _BankRequestsState extends State<BankRequests> {
  late Future<List<BloodRequestRecord>> requestsFuture;
  @override
  void initState() { super.initState(); requestsFuture = AppState.bankRequests(); }
  Color statusColor(String status) => status == 'Approved' ? Colors.green.shade700 : status == 'Rejected' ? Colors.red.shade700 : Colors.orange.shade800;

  Future<void> updateRequest(BloodRequestRecord request, String status) async {
    final updated = await AppState.updateRequestStatus(request, status);
    if (!mounted) return;
    if (!updated) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This request could not be updated.'))); return; }
    setState(() {
      requestsFuture = AppState.bankRequests();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request ${request.id} marked $status.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Incoming requests')), body: FutureBuilder<List<BloodRequestRecord>>(future: requestsFuture, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return const Center(child: Text('Could not load incoming requests.'));
    final requests = snapshot.data ?? [];
    if (requests.isEmpty) return const Center(child: Text('No incoming requests right now.'));
    return ListView(padding: const EdgeInsets.all(20), children: requests.map((request) { final color = statusColor(request.status); final isPending = request.status == 'Pending'; return Card(margin: const EdgeInsets.only(bottom: 14), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(backgroundColor: const Color(0xFFFFE8EA), child: Text(request.bloodGroup, style: const TextStyle(color: Color(0xFFB42332), fontWeight: FontWeight.w800, fontSize: 12))), const SizedBox(width: 12), Expanded(child: Text('${request.quantity} unit request', style: const TextStyle(fontWeight: FontWeight.w800))), Text(request.status, style: TextStyle(color: color, fontWeight: FontWeight.w700))]), const SizedBox(height: 12), Text(request.seekerName.isEmpty ? 'Seeker information unavailable' : 'From ${request.seekerName}'), if (request.seekerEmail.isNotEmpty) ...[const SizedBox(height: 3), Text(request.seekerEmail, style: const TextStyle(color: Color(0xFF876F73), fontSize: 12))], const SizedBox(height: 4), Text('${request.location}  |  ${request.dateTime}', style: const TextStyle(color: Color(0xFF876F73), fontSize: 12)), if (isPending) ...[const SizedBox(height: 14), Row(children: [Expanded(child: OutlinedButton(onPressed: () => updateRequest(request, 'Rejected'), child: const Text('Reject'))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () => updateRequest(request, 'Approved'), child: const Text('Approve')))])] ]))); }).toList());
  }));
}
