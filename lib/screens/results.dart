import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';
import 'details.dart';
import 'seek_auth.dart';

class Results extends StatefulWidget {
  const Results({super.key, required this.bloodGroup, required this.location});
  final String bloodGroup;
  final String location;
  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  late Future<List<BloodBankRecord>> banksFuture;
  @override
  void initState() {
    super.initState();
    banksFuture = AppState.searchBanks(
      bloodGroup: widget.bloodGroup,
      location: widget.location,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood bank results')),
      body: FutureBuilder<List<BloodBankRecord>>(
        future: banksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const _ResultsMessage(
              icon: Icons.error_outline,
              message: 'Could not load blood bank results.',
            );
          final banks = snapshot.data ?? [];
          if (banks.isEmpty)
            return const _ResultsMessage(
              icon: Icons.search_off,
              message: 'No blood banks found.',
            );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                'Results near ${widget.location}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.bloodGroup} blood  •  ${banks.length} banks found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              for (final bank in banks)
                _ResultCard(bank: bank, group: widget.bloodGroup),
            ],
          );
        },
      ),
    );
  }
}

class _ResultsMessage extends StatelessWidget {
  const _ResultsMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: const Color(0xFFB42332)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}

class _ResultCard extends StatefulWidget {
  const _ResultCard({required this.bank, required this.group});
  final BloodBankRecord bank;
  final String group;
  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  late Future<bool> savedFuture;

  BloodBankRecord get bank => widget.bank;
  String get group => widget.group;

  @override
  void initState() {
    super.initState();
    savedFuture = AppState.isSaved(bank);
  }

  Future<void> toggleSaved() async {
    if (AppState.session.user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SeekAuth()),
      );
      if (!mounted || AppState.session.user == null) return;
      savedFuture = AppState.isSaved(bank);
    }
    final saved = await AppState.toggleSaved(bank);
    if (!mounted) return;
    final future = Future.value(saved);
    setState(() {
      savedFuture = future;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Bank saved.' : 'Bank removed from saved banks.'),
      ),
    );
  }

  Color statusColor(String status) => status == 'Available'
      ? Colors.green.shade700
      : status == 'Low Stock'
      ? Colors.orange.shade800
      : Colors.red.shade700;
  Future<void> request(BuildContext context) async {
    if (AppState.session.user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SeekAuth()),
      );
      return;
    }
    final controller = TextEditingController(text: '1');
    String? validationError;
    Future<dynamic>? dialogCompleted;
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        dialogCompleted = ModalRoute.of(dialogContext)?.completed;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Request $group blood'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (max ${bank.unitsFor(group)})',
                errorText: validationError,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value == null ||
                      value <= 0 ||
                      value > bank.unitsFor(group)) {
                    setDialogState(
                      () => validationError =
                          'Enter a quantity from 1 to ${bank.unitsFor(group)}.',
                    );
                    return;
                  }
                  Navigator.pop(context, value);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
    await dialogCompleted;
    controller.dispose();
    if (quantity == null || !context.mounted) return;
    final error = await AppState.addRequest(
      bloodGroup: group,
      quantity: quantity,
      bank: bank,
    );
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Request created.')));
  }

  @override
  Widget build(BuildContext context) {
    final status = bank.statusFor(group);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Details(bank: bank, bloodGroup: group),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_hospital_outlined,
                    color: Color(0xFFB42332),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      bank.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (bank.verified)
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                  FutureBuilder<bool>(
                    future: savedFuture,
                    builder: (context, snapshot) => IconButton(
                      tooltip: 'Save bank',
                      onPressed: toggleSaved,
                      icon: Icon(
                        snapshot.data == true
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: const Color(0xFFB42332),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Text(
                    '$group  •  ${bank.unitsFor(group)} units',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor(status),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${bank.address}, ${bank.location}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                'Updated ${bank.lastUpdated}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF7B8794), fontSize: 11),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Details(bank: bank, bloodGroup: group),
                      ),
                    ),
                    child: const Text('View details'),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: bank.unitsFor(group) == 0
                          ? null
                          : () => request(context),
                      child: const Text('Request'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
