import 'package:flutter/material.dart';
import 'welcome.dart';

class QuickOverview extends StatefulWidget {
  const QuickOverview({super.key});

  @override
  State<QuickOverview> createState() => _QuickOverviewState();
}

class _QuickOverviewState extends State<QuickOverview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markAnimation;
  late final Animation<double> _headingAnimation;
  late final Animation<double> _descriptionAnimation;
  late final Animation<double> _pathAnimation;
  late final List<Animation<double>> _stageAnimations;
  late final List<Animation<double>> _connectorAnimations;
  late final Animation<double> _audienceAnimation;
  late final Animation<double> _continueAnimation;

  static const _stages = [
    _JourneyStage(
      icon: Icons.bloodtype_outlined,
      title: 'NEED BLOOD',
      description: 'Choose the blood group you need.',
    ),
    _JourneyStage(
      icon: Icons.search_rounded,
      title: 'SEARCH',
      description: 'Search by blood group and location.',
    ),
    _JourneyStage(
      icon: Icons.location_on_outlined,
      title: 'DISCOVER',
      description: 'See available blood banks and their details.',
    ),
    _JourneyStage(
      icon: Icons.send_outlined,
      title: 'REQUEST',
      description: 'Send a request to the selected bank.',
    ),
    _JourneyStage(
      icon: Icons.track_changes_outlined,
      title: 'TRACK',
      description: 'Follow your request status.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2850),
    )..forward();
    _markAnimation = _interval(0, 0.16);
    _headingAnimation = _interval(0.08, 0.28);
    _descriptionAnimation = _interval(0.2, 0.38);
    _pathAnimation = _interval(0.3, 0.84);
    _stageAnimations = List.generate(
      _stages.length,
      (index) => _interval(0.28 + index * 0.1, 0.42 + index * 0.1),
    );
    _connectorAnimations = List.generate(
      _stages.length - 1,
      (index) => _interval(0.37 + index * 0.1, 0.47 + index * 0.1),
    );
    _audienceAnimation = _interval(0.84, 0.95);
    _continueAnimation = _interval(0.95, 1);
  }

  Animation<double> _interval(double start, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fadeSlide(Animation<double> animation, Widget child) =>
      FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );

  Widget _fadeScale(Animation<double> animation, Widget child) =>
      FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF8F8)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverviewIntro(
                      markAnimation: _markAnimation,
                      headingAnimation: _headingAnimation,
                      descriptionAnimation: _descriptionAnimation,
                      fadeSlide: _fadeSlide,
                      fadeScale: _fadeScale,
                    ),
                    const SizedBox(height: 22),
                    _ResponsiveJourney(
                      stages: _stages,
                      stageAnimations: _stageAnimations,
                      connectorAnimations: _connectorAnimations,
                      pathAnimation: _pathAnimation,
                      fadeSlide: _fadeSlide,
                      fadeScale: _fadeScale,
                    ),
                    const SizedBox(height: 24),
                    _fadeSlide(_audienceAnimation, const _AudienceSummaries()),
                    const SizedBox(height: 6),
                    _fadeSlide(
                      _continueAnimation,
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Welcome(),
                              ),
                            );
                          },
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                          ),
                          label: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _JourneyStage {
  const _JourneyStage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _OverviewIntro extends StatelessWidget {
  const _OverviewIntro({
    required this.markAnimation,
    required this.headingAnimation,
    required this.descriptionAnimation,
    required this.fadeSlide,
    required this.fadeScale,
  });

  final Animation<double> markAnimation;
  final Animation<double> headingAnimation;
  final Animation<double> descriptionAnimation;
  final Widget Function(Animation<double>, Widget) fadeSlide;
  final Widget Function(Animation<double>, Widget) fadeScale;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          fadeScale(markAnimation, const _MedicalMark()),
          const SizedBox(height: 14),
          fadeSlide(
            headingAnimation,
            Text(
              'Every drop can make a difference.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF172B4D),
                fontSize: compact ? 34 : 44,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          fadeSlide(
            descriptionAnimation,
            const Text(
              'Blood Bank Locator connects people who need blood with\nblood banks that can help.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF52606D),
                fontSize: 17,
                height: 1.45,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _MedicalMark extends StatelessWidget {
  const _MedicalMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3F4),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFF3D9DC)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14B42332),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: const Icon(
      Icons.bloodtype_rounded,
      color: Color(0xFFB42332),
      size: 34,
    ),
  );
}

class _ResponsiveJourney extends StatelessWidget {
  const _ResponsiveJourney({
    required this.stages,
    required this.stageAnimations,
    required this.connectorAnimations,
    required this.pathAnimation,
    required this.fadeSlide,
    required this.fadeScale,
  });

  final List<_JourneyStage> stages;
  final List<Animation<double>> stageAnimations;
  final List<Animation<double>> connectorAnimations;
  final Animation<double> pathAnimation;
  final Widget Function(Animation<double>, Widget) fadeSlide;
  final Widget Function(Animation<double>, Widget) fadeScale;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 760) {
        return _HorizontalJourney(
          stages: stages,
          stageAnimations: stageAnimations,
          pathAnimation: pathAnimation,
          fadeSlide: fadeSlide,
          fadeScale: fadeScale,
        );
      }
      return _VerticalJourney(
        stages: stages,
        stageAnimations: stageAnimations,
        connectorAnimations: connectorAnimations,
        fadeSlide: fadeSlide,
        fadeScale: fadeScale,
      );
    },
  );
}

class _HorizontalJourney extends StatelessWidget {
  const _HorizontalJourney({
    required this.stages,
    required this.stageAnimations,
    required this.pathAnimation,
    required this.fadeSlide,
    required this.fadeScale,
  });

  final List<_JourneyStage> stages;
  final List<Animation<double>> stageAnimations;
  final Animation<double> pathAnimation;
  final Widget Function(Animation<double>, Widget) fadeSlide;
  final Widget Function(Animation<double>, Widget) fadeScale;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 150,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: pathAnimation,
                  builder: (context, child) => CustomPaint(
                    painter: _JourneyPathPainter(progress: pathAnimation.value),
                  ),
                ),
              ),
              for (var index = 0; index < stages.length; index++)
                Positioned(
                  left:
                      constraints.maxWidth * (index + 0.5) / stages.length -
                      _markerSize(index) / 2,
                  top: _markerCenter(index) - _markerSize(index) / 2,
                  width: _markerSize(index),
                  height: _markerSize(index),
                  child: fadeScale(
                    stageAnimations[index],
                    _JourneyMarker(
                      stage: stages[index],
                      size: _markerSize(index),
                      central: index == 2,
                      emphasized: index == 0 || index == stages.length - 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < stages.length; index++)
            Expanded(
              child: fadeSlide(
                stageAnimations[index],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _JourneyCopy(stage: stages[index], centered: true),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  double _markerCenter(int index) => index.isEven ? 62 : 96;

  double _markerSize(int index) {
    if (index == 2) return 82;
    if (index == 0 || index == stages.length - 1) return 58;
    return 48;
  }
}

class _JourneyPathPainter extends CustomPainter {
  const _JourneyPathPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final points = List<Offset>.generate(
      5,
      (index) => Offset(size.width * (index + 0.5) / 5, index.isEven ? 62 : 96),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index++) {
      final first = points[index];
      final second = points[index + 1];
      final midpoint = (first.dx + second.dx) / 2;
      path.cubicTo(
        midpoint,
        first.dy,
        midpoint,
        second.dy,
        second.dx,
        second.dy,
      );
    }
    final basePaint = Paint()
      ..color = const Color(0xFFF1D9DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = const Color(0xFFB42332)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, basePaint);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_JourneyPathPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _VerticalJourney extends StatelessWidget {
  const _VerticalJourney({
    required this.stages,
    required this.stageAnimations,
    required this.connectorAnimations,
    required this.fadeSlide,
    required this.fadeScale,
  });

  final List<_JourneyStage> stages;
  final List<Animation<double>> stageAnimations;
  final List<Animation<double>> connectorAnimations;
  final Widget Function(Animation<double>, Widget) fadeSlide;
  final Widget Function(Animation<double>, Widget) fadeScale;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < stages.length; index++) ...[
        fadeSlide(
          stageAnimations[index],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Center(
                  child: fadeScale(
                    stageAnimations[index],
                    _JourneyMarker(
                      stage: stages[index],
                      size: index == 0
                          ? 56
                          : index == 2
                          ? 50
                          : 42,
                      central: index == 2,
                      emphasized: index == 0 || index == stages.length - 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _JourneyCopy(stage: stages[index])),
            ],
          ),
        ),
        if (index < connectorAnimations.length)
          _VerticalConnector(animation: connectorAnimations[index]),
      ],
    ],
  );
}

class _JourneyMarker extends StatelessWidget {
  const _JourneyMarker({
    required this.stage,
    required this.size,
    required this.central,
    required this.emphasized,
  });

  final _JourneyStage stage;
  final double size;
  final bool central;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: central ? const Color(0xFFB42332) : Colors.white,
      shape: BoxShape.circle,
      border: Border.all(
        color: central
            ? const Color(0xFFB42332)
            : emphasized
            ? const Color(0xFFE8BFC4)
            : const Color(0xFFE1E6EB),
        width: central ? 0 : 1.3,
      ),
      boxShadow: [
        BoxShadow(
          color: central ? const Color(0x30B42332) : const Color(0x0D172B4D),
          blurRadius: central ? 20 : 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(
      stage.icon,
      size: central ? size * 0.48 : size * 0.46,
      color: central ? Colors.white : const Color(0xFFB42332),
    ),
  );
}

class _JourneyCopy extends StatelessWidget {
  const _JourneyCopy({required this.stage, this.centered = false});

  final _JourneyStage stage;
  final bool centered;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Text(
        stage.title,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          color: Color(0xFF9E2633),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        stage.description,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: const Color(0xFF52606D),
          fontSize: centered ? 14 : 15,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _VerticalConnector extends StatelessWidget {
  const _VerticalConnector({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 58,
    height: 28,
    child: Align(
      alignment: Alignment.topCenter,
      child: SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        alignment: Alignment.topCenter,
        child: const SizedBox(
          width: 58,
          height: 28,
          child: CustomPaint(painter: _VerticalPathPainter()),
        ),
      ),
    ),
  );
}

class _VerticalPathPainter extends CustomPainter {
  const _VerticalPathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB42332)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height - 6)
      ..moveTo(size.width / 2 - 4, size.height - 11)
      ..lineTo(size.width / 2, size.height - 6)
      ..lineTo(size.width / 2 + 4, size.height - 11);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_VerticalPathPainter oldDelegate) => false;
}

class _AudienceSummaries extends StatelessWidget {
  const _AudienceSummaries();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      const seekers = _AudienceSummary(
        title: 'BLOOD SEEKERS',
        description:
            'Find availability, nearby banks, send requests and keep track of them.',
        icon: Icons.person_search_outlined,
      );
      const banks = _AudienceSummary(
        title: 'BLOOD BANKS',
        description:
            'Manage stock, receive requests and keep availability updated.',
        icon: Icons.local_hospital_outlined,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE7D9DB)),
          const SizedBox(height: 16),
          const Text(
            'Built for both sides of the connection',
            style: TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (compact)
            const Column(children: [seekers, SizedBox(height: 14), banks])
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: seekers),
                SizedBox(width: 28),
                SizedBox(
                  height: 68,
                  child: VerticalDivider(width: 1, color: Color(0xFFE7D9DB)),
                ),
                SizedBox(width: 28),
                Expanded(child: banks),
              ],
            ),
        ],
      );
    },
  );
}

class _AudienceSummary extends StatelessWidget {
  const _AudienceSummary({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFFB42332), size: 24),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF9E2633),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF52606D),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
