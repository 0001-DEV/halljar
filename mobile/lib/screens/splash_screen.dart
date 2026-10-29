import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'market/market_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pushController;
  late Animation<double> _pushAnimation;

  late AnimationController _dissolveController;
  late Animation<double> _dissolveOpacity;
  late Animation<double> _dissolveScale;

  late AnimationController _morphController;
  late Animation<Color?> _textColorAnimation;

  late AnimationController _taglineController;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Deliberate, smooth inward push animation (0 to 1.7s)
    _pushController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _pushAnimation = CurvedAnimation(
      parent: _pushController,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );

    // 2. Avatar dissolve animation (starts at 1.7s, duration 600ms)
    _dissolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _dissolveOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(_dissolveController);
    _dissolveScale = Tween<double>(begin: 1.0, end: 1.8).animate(_dissolveController);

    // 3. Text morph & glow animation to radiant gold
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _textColorAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFFFACC15), // Glowing Gold
    ).animate(_morphController);

    // 4. Tagline fade in
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 0.95).animate(_taglineController);

    _startSequence();
  }

  void _startSequence() async {
    await _pushController.forward();
    _dissolveController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _morphController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    _taglineController.forward();

    // Auto-proceed to Market or Login after 3.4 seconds total
    await Future.delayed(const Duration(milliseconds: 1200));
    _proceed();
  }

  void _proceed() {
    if (!mounted) return;
    final target = AuthService.currentUser != null ? const MarketScreen() : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pushController.dispose();
    _dissolveController.dispose();
    _morphController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _proceed, // Tap anywhere to skip instantly
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Color(0xFF115E59), // Primary Emerald
                Color(0xFF0F766E),
                Color(0xFF042F2E), // Deep Dark Teal
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([
                  _pushAnimation,
                  _dissolveController,
                  _morphController,
                ]),
                builder: (context, _) {
                  final pushVal = _pushAnimation.value;
                  // Left group starts at -180px and slides to 0
                  final leftOffset = (1.0 - pushVal) * -180.0;
                  // Right group starts at +180px and slides to 0
                  final rightOffset = (1.0 - pushVal) * 180.0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left pusher + 'Hall'
                      Transform.translate(
                        offset: Offset(leftOffset, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Left avatar flipped horizontally (scaleX: -1) to face RIGHT towards 'Hall'
                            FadeTransition(
                              opacity: _dissolveOpacity,
                              child: Transform.scale(
                                scaleX: -1.0 * _dissolveScale.value,
                                scaleY: _dissolveScale.value,
                                child: const Text(
                                  '🏃‍♂️',
                                  style: TextStyle(fontSize: 38),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hall',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                                color: _textColorAnimation.value,
                                shadows: [
                                  Shadow(
                                    color: _textColorAnimation.value == const Color(0xFFFACC15)
                                        ? const Color(0xFFFACC15).withOpacity(0.85)
                                        : Colors.black38,
                                    blurRadius: _textColorAnimation.value == const Color(0xFFFACC15) ? 22 : 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right side: 'jar' + avatar pushing inward
                      Transform.translate(
                        offset: Offset(rightOffset, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'jar',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                                color: _textColorAnimation.value,
                                shadows: [
                                  Shadow(
                                    color: _textColorAnimation.value == const Color(0xFFFACC15)
                                        ? const Color(0xFFFACC15).withOpacity(0.85)
                                        : Colors.black38,
                                    blurRadius: _textColorAnimation.value == const Color(0xFFFACC15) ? 22 : 12,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Right avatar naturally faces LEFT (inward) towards 'jar'
                            FadeTransition(
                              opacity: _dissolveOpacity,
                              child: Transform.scale(
                                scale: _dissolveScale.value,
                                child: const Text(
                                  '🏃‍♀️',
                                  style: TextStyle(fontSize: 38),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Subtitle Tagline
              Positioned(
                bottom: 120,
                child: FadeTransition(
                  opacity: _taglineOpacity,
                  child: const Text(
                    'CITI-VIEW & ESTATE MARKETPLACE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Skip hint
              const Positioned(
                bottom: 30,
                child: Text(
                  'Tap anywhere to skip',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
