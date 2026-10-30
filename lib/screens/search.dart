import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'results.dart';

class Search extends StatefulWidget {
  const Search({super.key, this.initialBloodGroup, this.initialLocation});
  final String? initialBloodGroup;
  final String? initialLocation;

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String? selectedBloodGroup;
  final locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedBloodGroup = widget.initialBloodGroup;
    locationController.text = widget.initialLocation ?? '';
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  void submitSearch() {
    final location = locationController.text.trim();

    if (selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a blood group to search.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Results(
          bloodGroup: selectedBloodGroup!,
          location: location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Blood'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bloodtype, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find blood near you',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text('Choose a group and optionally narrow by location.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Blood group',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedBloodGroup,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.water_drop_outlined),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                hintText: 'Select blood group',
              ),
              items: AppState.bloodGroups.map((group) {
                return DropdownMenuItem(value: group, child: Text(group));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBloodGroup = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Location',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: locationController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'Enter city or area',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: submitSearch,
                icon: const Icon(Icons.search),
                label: const Text('Find Blood Banks'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}