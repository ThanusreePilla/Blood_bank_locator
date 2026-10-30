import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'bank_home.dart';
import 'quick_overview.dart';
import 'seek_home.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            final role = AppState.session.user?.role;
            if (role == 'seeker') return const SeekHome();
            if (role == 'bank') return const BankHome();
            return const QuickOverview();
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE8EA), Color(0xFFFFF9F9)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB42332),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26B42332),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bloodtype_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Blood Bank Locator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF172B4D),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find blood. Connect faster. Save lives.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB42332),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check blood availability and connect with nearby blood banks when it matters most.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF624E52),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 34),
                const SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    backgroundColor: Color(0x33B42332),
                    color: Color(0xFFB42332),
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
