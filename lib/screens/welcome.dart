import 'package:flutter/material.dart';
import 'auth.dart';
import 'search.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE8EA), Color(0xFFFFF9F9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB42332),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.water_drop, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'BloodLink',
                    style: TextStyle(
                      color: Color(0xFF8D1D2A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 72),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1FB42332),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bloodtype_rounded,
                  color: Color(0xFFB42332),
                  size: 62,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Find Blood\nWhen You Need It',
                style: TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w800, color: Color(0xFF172B4D)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search verified blood banks, check availability, and send a request with confidence.',
                style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF52606D)),
              ),
              const SizedBox(height: 56),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Search(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Find Blood'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Auth(),
                      ),
                    );
                  },
                  child: const Text('Sign In / Register'),
                ),
              ),

              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'A faster connection between people and care.',
                  style: TextStyle(color: Color(0xFF876F73)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}