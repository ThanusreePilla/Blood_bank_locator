import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';
import 'seek_auth.dart';

class Details extends StatefulWidget {
  const Details({super.key, required this.bank, required this.bloodGroup});
  final BloodBankRecord bank;
  final String bloodGroup;
  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late Future<bool> savedFuture;
  BloodBankRecord? liveBank;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    savedFuture = AppState.isSaved(widget.bank);
    _refreshBank();
  }

  Future<void> _refreshBank() async {
    if (widget.bank.id == null) return;
    final bank = await AppState.bankById(widget.bank.id!);
    if (mounted && bank != null) setState(() => liveBank = bank);
  }

  Future<void> toggleSaved() async {
    if (AppState.session.user == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SeekAuth()));
      if (!mounted || AppState.session.user == null) return;
      savedFuture = AppState.isSaved(liveBank ?? widget.bank);
    }
    setState(() => busy = true);
    final saved = await AppState.toggleSaved(liveBank ?? widget.bank);
    if (!mounted) return;
    setState(() {
      busy = false;
      savedFuture = Future.value(saved);
    });
  }

  Future<void> submitRequest() async {
    if (AppState.session.user == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SeekAuth()));
      if (mounted) _refreshBank();
      return;
    }
    final bank = liveBank ?? widget.bank;
    final controller = TextEditingController(text: '1');
    String? validationError;
    Future<dynamic>? dialogCompleted;
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        dialogCompleted = ModalRoute.of(dialogContext)?.completed;
        return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text('Request ${widget.bloodGroup} blood'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantity (max ${bank.unitsFor(widget.bloodGroup)})',
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
              if (value == null || value <= 0 || value > bank.unitsFor(widget.bloodGroup)) {
                setDialogState(() => validationError = 'Enter a quantity from 1 to ${bank.unitsFor(widget.bloodGroup)}.');
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Submit request'),
          ),
        ],
      ));
      },
    );
    await dialogCompleted;
    controller.dispose();
    if (!mounted || quantity == null) return;
    setState(() => busy = true);
    final error = await AppState.addRequest(
      bloodGroup: widget.bloodGroup,
      quantity: quantity,
      bank: bank,
    );
    if (!mounted) return;
    setState(() => busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Blood request submitted successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = liveBank ?? widget.bank;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood bank details'),
        actions: [
          FutureBuilder<bool>(
            future: savedFuture,
            builder: (context, snapshot) => IconButton(
              tooltip: 'Save bank',
              onPressed: busy ? null : toggleSaved,
              icon: Icon(
                snapshot.data == true ? Icons.bookmark : Icons.bookmark_border,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFFE8EA),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFFB42332),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  bank.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bank.verified ? 'Verified blood bank' : 'Verification pending',
            style: TextStyle(
              color: bank.verified
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          _Section(
            title: 'Contact information',
            children: [
              _Detail(
                label: 'Address',
                value: '${bank.address}, ${bank.location}',
              ),
              _Detail(label: 'Phone', value: bank.contact),
              _Detail(label: 'Email', value: bank.email),
              _Detail(label: 'Opening hours', value: bank.openingHours),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Available blood groups',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppState.bloodGroups
                    .map(
                      (group) => Chip(
                        label: Text('$group  ${bank.unitsFor(group)}'),
                        backgroundColor: bank.unitsFor(group) > 0
                            ? const Color(0xFFEAF6EE)
                            : const Color(0xFFF5EEEE),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              const Text(
                'Stock is loaded from the local SQLite database.',
                style: TextStyle(fontSize: 12, color: Color(0xFF876F73)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: busy || bank.unitsFor(widget.bloodGroup) == 0
                  ? null
                  : submitRequest,
              icon: const Icon(Icons.bloodtype),
              label: Text(
                bank.unitsFor(widget.bloodGroup) == 0
                    ? 'Currently unavailable'
                    : 'Request ${widget.bloodGroup} blood',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF876F73)),
        ),
        const SizedBox(height: 2),
        Text(value),
      ],
    ),
  );
}
