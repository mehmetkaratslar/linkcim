import 'package:flutter/material.dart';
import 'package:linkcim/screens/home_screen.dart';

// Temiz ve Basit Splash Screen - İzin kontrolü YOK!
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon controller'ını başlat
    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    // Fade animasyonu
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Scale animasyonu
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Animasyonu başlat
    _animationController.forward();

    // 2.5 saniye sonra direkt ana ekrana geç - İZİN KONTROLÜ YOK!
    Future.delayed(Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 300),
          ),
        );
      }
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
      backgroundColor: Colors.blue[600],
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.video_library,
                        size: 60,
                        color: Colors.blue[600],
                      ),
                    ),

                    SizedBox(height: 32),

                    // App name
                    Text(
                      'Linkcim',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: 8),

                    // App tagline
                    Text(
                      'Akıllı Video Kayıt ve Kategorilendirme',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 48),

                    // Loading indicator
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Loading text
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
