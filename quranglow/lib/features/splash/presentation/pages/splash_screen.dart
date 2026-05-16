import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🚀 High-Performance Optimization: Precache heavy home background images 
    // while the user is watching the beautiful splash animations!
    precacheImage(const AssetImage('assets/images/app_bg_dark.png'), context);
    precacheImage(const AssetImage('assets/images/app_bg_light.png'), context);
    precacheImage(const AssetImage('assets/images/islamic_pattern.png'), context);
    
    // 🏰 Precache Level Nodes (Gates) for the Roadmap
    precacheImage(const AssetImage('assets/images/gate_locked.png'), context);
    precacheImage(const AssetImage('assets/images/gate_active.png'), context);
    precacheImage(const AssetImage('assets/images/gate_unlocked.png'), context);
    precacheImage(const AssetImage('assets/images/quran_completed.png'), context);

    // 🌳 Precache Main Icons
    precacheImage(const AssetImage('assets/images/bustan_icon.png'), context);
    precacheImage(const AssetImage('assets/images/bustan_splash.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final isDark = b == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/bustan_splash.png'),
              fit: BoxFit.cover,
              colorFilter: isDark 
                ? ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)
                : null,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ✨ Glowing Ambient Light
              Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(isDark ? 0.15 : 0.2),
                            blurRadius: 120,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 1200.ms)
                  .scale(begin: const Offset(0.5, 0.5)),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80), // Move content higher up
                  child: Column(
                    children: [
                      const Spacer(flex: 1), // Smaller top spacer to raise content
                      // 🌳 The Brand Logo (Bustan) - Now Rounded Square
                      Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05), // Added for glass effect
                              borderRadius: BorderRadius.circular(44), // Curved square
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2), // Lighter border for glass look
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Opacity(
                                  opacity: 0.85, // Premium transparency
                                  child: Image.asset(
                                    'assets/images/bustan_icon.png',
                                    height: 180,
                                    width: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          )
                          .shimmer(
                            delay: 1500.ms,
                            duration: 1200.ms,
                            color: Colors.white24,
                          ),

                      const SizedBox(height: 80),

                      // ⏳ Minimalist Progress
                      SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: cs.primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.primary.withOpacity(0.5),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1200.ms)
                          .scaleX(begin: 0, duration: 2000.ms),
                      
                      const Spacer(flex: 3), // Larger bottom spacer to push everything up
                    ],
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
