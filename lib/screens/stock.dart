import 'package:flutter/material.dart';
import '../services/app_state.dart';

class Stock extends StatefulWidget {
  const Stock({super.key});
  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  String statusFor(int units) => units == 0 ? 'Out of Stock' : units <= 5 ? 'Low Stock' : 'Available';
  Color statusColor(BuildContext context, int units) => units == 0 ? Theme.of(context).colorScheme.error : units <= 5 ? Colors.orange.shade800 : Colors.green.shade700;

  Future<void> editUnits(String group) async {
    final bank = AppState.session.bank;
    if (bank == null) return;
    final controller = TextEditingController(text: '${bank.unitsFor(group)}');
    String? validationError;
    Future<dynamic>? dialogCompleted;
    final updatedUnits = await showDialog<int>(context: context, builder: (dialogContext) {
      dialogCompleted = ModalRoute.of(dialogContext)?.completed;
      return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(title: Text('Update $group stock'), content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Available units', prefixIcon: const Icon(Icons.inventory_2_outlined), errorText: validationError)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { final units = int.tryParse(controller.text.trim()); if (units == null || units < 0) { setDialogState(() => validationError = 'Enter a whole number of zero or more.'); return; } Navigator.pop(context, units); }, child: const Text('Save'))]));
    });
    await dialogCompleted;
    controller.dispose();
    if (!mounted || updatedUnits == null) return;
    final error = await AppState.updateStock(bank, group, updatedUnits);
    if (!mounted) return;
    if (error != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))); return; }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock updated successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    final bank = AppState.session.bank;
    if (bank == null) return const Scaffold(body: Center(child: Text('Bank session expired.')));
    return Scaffold(appBar: AppBar(title: const Text('Manage Blood Stock')), body: ListView(padding: const EdgeInsets.all(20), children: [Text('Current inventory', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), const Text('Updates are saved to the local SQLite database.'), const SizedBox(height: 24), ...AppState.bloodGroups.map((group) { final units = bank.unitsFor(group); final color = statusColor(context, units); return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Text(group, style: TextStyle(color: color, fontWeight: FontWeight.bold))), title: Text('$units units'), subtitle: Text(statusFor(units), style: TextStyle(color: color, fontWeight: FontWeight.w600)), trailing: IconButton(tooltip: 'Edit $group stock', onPressed: () => editUnits(group), icon: const Icon(Icons.edit_outlined)))); })]));
  }
}
