import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  late Future<List<BloodRequestRecord>> requestsFuture;

  @override
  void initState() {
    super.initState();
    requestsFuture = AppState.seekerRequests();
  }

  Color statusColor(String status) => status == 'Approved' ? Colors.green.shade700 : status == 'Rejected' ? Colors.red.shade700 : Colors.orange.shade800;

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('My requests')), body: FutureBuilder<List<BloodRequestRecord>>(future: requestsFuture, builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return const Center(child: Text('Could not load your requests.'));
    final requests = snapshot.data ?? [];
    if (requests.isEmpty) return const Center(child: Text('Your blood requests will appear here.'));
    return ListView(padding: const EdgeInsets.all(20), children: requests.map((request) { final color = statusColor(request.status); return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(backgroundColor: const Color(0xFFFFE8EA), child: Text(request.bloodGroup, style: const TextStyle(color: Color(0xFFB42332), fontSize: 12, fontWeight: FontWeight.w800))), const SizedBox(width: 12), Expanded(child: Text('${request.quantity} unit request', style: const TextStyle(fontWeight: FontWeight.w800))), Text(request.status, style: TextStyle(color: color, fontWeight: FontWeight.w700))]), const SizedBox(height: 12), Text(request.bankName), const SizedBox(height: 4), Text('${request.location}  |  ${request.dateTime}', style: const TextStyle(color: Color(0xFF876F73), fontSize: 12)), const SizedBox(height: 8), Text('Request #${request.id}', style: const TextStyle(color: Color(0xFF876F73), fontSize: 12))]))); }).toList());
  }));
}
