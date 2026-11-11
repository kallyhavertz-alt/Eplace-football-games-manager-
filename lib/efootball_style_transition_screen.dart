import 'dart:math' as math;
import 'package:flutter/material.dart';

class EFootballStyleTransitionScreen extends StatefulWidget {
  final VoidCallback onAnimationFinished;

  const EFootballStyleTransitionScreen({
    Key? key,
    required this.onAnimationFinished,
  }) : super(key: key);

  @override
  State<EFootballStyleTransitionScreen> createState() =>
      _EFootballStyleTransitionScreenState();
}

class _EFootballStyleTransitionScreenState
    extends State<EFootballStyleTransitionScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;

  late Animation<double> _spinAnimation;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  bool _isLogoPhase = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _spinAnimation = Tween<double>(begin: 0.0, end: 3 * 2 * math.pi).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

     _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeIn),
      ),
    );


    _mainController.addListener(() {
      if (_mainController.value >= 0.6 && !_isLogoPhase) {
        setState(() {
          _isLogoPhase = true;
        });
      }
    });


    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationFinished();
      }
    });

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: !_isLogoPhase
            ? Container(
          key: const ValueKey('LoaderPhase'),
          color: const Color(0xFFFFD700),
          child: Center(
            child: AnimatedBuilder(
              animation: _spinAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _spinAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withOpacity(0.15),
                    width: 4,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: CircularProgressIndicator(
                    color: Colors.black87,
                    strokeWidth: 3.5,
                  ),
                ),
              ),
            ),
          ),
        )
            : Container(
          key: const ValueKey('LogoPhase'),
          color: const Color(0xFF00113B),
          child: Center(
            child: FadeTransition(
              opacity: _logoFadeAnimation,
              child: ScaleTransition(
                scale: _logoScaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 50,
                        color: Color(0xFF00113B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "LEAGUE MANAGER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "THE PITCH IS OURS",
                      style: TextStyle(
                        color: const Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}