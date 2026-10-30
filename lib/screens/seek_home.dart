import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/app_state.dart';
import 'details.dart';
import 'history.dart';
import 'nearby.dart';
import 'profile.dart';
import 'search.dart';
import 'welcome.dart';

class SeekHome extends StatefulWidget {
  const SeekHome({super.key});
  @override
  State<SeekHome> createState() => _SeekHomeState();
}

class _SeekHomeState extends State<SeekHome> {
  final locationController = TextEditingController(text: 'Central City');
  String selectedGroup = 'O+';
  int navigationIndex = 0;
  late Future<_DashboardData> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = _loadDashboard();
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  Future<_DashboardData> _loadDashboard() async => _DashboardData(banks: await AppState.nearbyBanks(), requests: await AppState.seekerRequests());
  void refresh() => setState(() => dashboardFuture = _loadDashboard());
  Future<void> openSearch() async {
    final location = locationController.text.trim();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => Search(initialBloodGroup: selectedGroup, initialLocation: location)));
    if (mounted) refresh();
  }
  String get firstName => AppState.seekerName.trim().split(' ').first;

  void openTab(int index) {
    setState(() => navigationIndex = index);
    if (index == 0) return;
    final destination = switch (index) { 1 => const Search(), 2 => const History(), _ => const Profile() };
    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  Future<void> logout() async {
    await AppState.resetSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Welcome()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Hello, $firstName'), actions: [IconButton(tooltip: 'Profile', onPressed: () => openTab(3), icon: const Icon(Icons.account_circle_outlined)), PopupMenuButton<String>(onSelected: (value) { if (value == 'logout') logout(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Log out'))])]),
    body: FutureBuilder<_DashboardData>(future: dashboardFuture, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _ErrorState(onRetry: refresh);
      final data = snapshot.data!;
      final firstBank = data.banks.isEmpty ? null : data.banks.first;
      return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        _SearchPanel(selectedGroup: selectedGroup, locationController: locationController, onGroupChanged: (value) => setState(() => selectedGroup = value), onSearch: openSearch),
        const SizedBox(height: 20),
        const Text('Quick actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 54, children: [_Action(icon: Icons.search, label: 'Search Blood', onTap: openSearch), _Action(icon: Icons.location_on_outlined, label: 'Nearby Banks', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Nearby()))), _Action(icon: Icons.receipt_long_outlined, label: 'My Requests', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const History()))), _Action(icon: Icons.bookmark_border, label: 'Saved Banks', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBanks()))) ]),
        const SizedBox(height: 20),
        const _SectionHeading(title: 'Blood Availability'),
        const SizedBox(height: 10),
        if (firstBank == null) const _EmptyState(text: 'No blood stock is available yet.') else Row(children: ['A+', 'B+', 'O+'].map((group) => Expanded(child: Padding(padding: EdgeInsets.only(right: group == 'O+' ? 0 : 8), child: _Availability(group: group, units: firstBank.unitsFor(group))))).toList()),
        const SizedBox(height: 20),
        _SectionHeading(title: 'Nearby Blood Banks', action: 'See all', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Nearby()))),
        const SizedBox(height: 10),
        if (data.banks.isEmpty) const _EmptyState(text: 'No blood banks found.') else ...data.banks.take(3).map((bank) => _BankPreview(bank: bank, group: 'O+', onTap: bank.id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => Details(bank: bank, bloodGroup: 'O+'))))),
        const SizedBox(height: 20),
        const _SectionHeading(title: 'Recent Request'),
        const SizedBox(height: 10),
        if (data.requests.isEmpty) const _EmptyRequest() else _RequestPreview(request: data.requests.first),
      ]);
    }),
    bottomNavigationBar: NavigationBar(selectedIndex: navigationIndex, onDestinationSelected: openTab, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.search), label: 'Search'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Requests'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile')]),
  );
}

class _DashboardData {
  const _DashboardData({required this.banks, required this.requests});
  final List<BloodBankRecord> banks;
  final List<BloodRequestRecord> requests;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Could not load the dashboard.'), const SizedBox(height: 10), OutlinedButton(onPressed: onRetry, child: const Text('Retry'))]));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(text, style: const TextStyle(color: Color(0xFF624E52)))));
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({required this.selectedGroup, required this.locationController, required this.onGroupChanged, required this.onSearch});
  final String selectedGroup;
  final TextEditingController locationController;
  final ValueChanged<String> onGroupChanged;
  final VoidCallback onSearch;
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFFB42332), margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Find Blood Near You', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 12), const Text('Blood group', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 5), DropdownButtonFormField<String>(initialValue: selectedGroup, dropdownColor: Colors.white, decoration: const InputDecoration(prefixIcon: Icon(Icons.bloodtype_outlined, size: 19), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9)), items: AppState.bloodGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(), onChanged: (value) { if (value != null) onGroupChanged(value); }), const SizedBox(height: 10), const Text('Location', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 5), TextField(controller: locationController, textInputAction: TextInputAction.search, decoration: const InputDecoration(hintText: 'City or area', prefixIcon: Icon(Icons.location_on_outlined, size: 19), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9))), const SizedBox(height: 12), SizedBox(width: double.infinity, height: 42, child: ElevatedButton.icon(onPressed: onSearch, icon: const Icon(Icons.search, size: 18), label: const Text('Search'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFB42332), padding: EdgeInsets.zero))) ])));
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(margin: EdgeInsets.zero, elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFEADBDD))), child: InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), child: Row(children: [Icon(icon, size: 19, color: const Color(0xFFB42332)), const SizedBox(width: 7), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))]))));
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), if (action != null) TextButton(onPressed: onAction, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text(action!, style: const TextStyle(color: Color(0xFFB42332), fontWeight: FontWeight.w700, fontSize: 12)))]);
}

class _Availability extends StatelessWidget {
  const _Availability({required this.group, required this.units});
  final String group;
  final int units;
  @override
  Widget build(BuildContext context) { final status = units == 0 ? 'Unavailable' : units <= 5 ? 'Low Stock' : 'Available'; final color = units == 0 ? Colors.red.shade700 : units <= 5 ? Colors.orange.shade800 : Colors.green.shade700; return Card(margin: EdgeInsets.zero, elevation: 1, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(group, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFB42332))), const SizedBox(height: 5), Text('$units units', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))]))); }
}

class _BankPreview extends StatelessWidget {
  const _BankPreview({required this.bank, required this.group, required this.onTap});
  final BloodBankRecord bank;
  final String group;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) { final units = bank.unitsFor(group); final color = units == 0 ? Colors.red.shade700 : units <= 5 ? Colors.orange.shade800 : Colors.green.shade700; return Card(margin: const EdgeInsets.only(bottom: 8), elevation: 1, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 8, 10), child: Row(children: [const Icon(Icons.local_hospital_outlined, color: Color(0xFFB42332), size: 21), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(bank.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 4), Text('$group  •  $units units  •  ${bank.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF624E52)))])), Text(bank.statusFor(group), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(width: 7), const Text('View', style: TextStyle(color: Color(0xFFB42332), fontSize: 12, fontWeight: FontWeight.w800))])))); }
}

class _RequestPreview extends StatelessWidget {
  const _RequestPreview({required this.request});
  final BloodRequestRecord request;
  @override
  Widget build(BuildContext context) { final color = request.status == 'Approved' ? Colors.green.shade700 : request.status == 'Rejected' ? Colors.red.shade700 : Colors.orange.shade800; return Card(margin: EdgeInsets.zero, child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), leading: CircleAvatar(backgroundColor: const Color(0xFFFFE8EA), child: Text(request.bloodGroup, style: const TextStyle(color: Color(0xFFB42332), fontSize: 12, fontWeight: FontWeight.w800))), title: Text('${request.quantity} unit request', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text(request.bankName, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text(request.status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)))); }
}

class _EmptyRequest extends StatelessWidget {
  const _EmptyRequest();
  @override
  Widget build(BuildContext context) => const _EmptyState(text: 'No blood requests yet.');
}

class SavedBanks extends StatefulWidget {
  const SavedBanks({super.key});
  @override
  State<SavedBanks> createState() => _SavedBanksState();
}

class _SavedBanksState extends State<SavedBanks> {
  late Future<List<BloodBankRecord>> banksFuture;

  @override
  void initState() {
    super.initState();
    banksFuture = AppState.savedBanks();
  }

  Future<void> _openBank(BloodBankRecord bank) async {
    final group = AppState.bloodGroups.firstWhere(
      (value) => bank.unitsFor(value) > 0,
      orElse: () => AppState.bloodGroups.first,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Details(
          bank: bank,
          bloodGroup: group,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => banksFuture = AppState.savedBanks());
  }

  Future<void> _removeBank(BloodBankRecord bank) async {
    await AppState.toggleSaved(bank);
    if (!mounted) return;
    setState(() => banksFuture = AppState.savedBanks());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bank removed from saved banks.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved blood banks')),
      body: FutureBuilder<List<BloodBankRecord>>(
        future: banksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load saved blood banks.'));
          }
          final banks = snapshot.data ?? [];
          if (banks.isEmpty) {
            return const Center(child: Text('No saved blood banks yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: banks
                .map(
                  (bank) => Card(
                    child: ListTile(
                      onTap: () => _openBank(bank),
                      leading: const Icon(
                        Icons.bookmark,
                        color: Color(0xFFB42332),
                      ),
                      title: Text(bank.name),
                      subtitle: Text(bank.location),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        onPressed: () => _removeBank(bank),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
