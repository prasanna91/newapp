import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../config/env_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(seconds: int.tryParse(EnvConfig.splashDuration) ?? 4),
      vsync: this,
    );

    switch (EnvConfig.splashAnimation) {
      case 'zoom':
        _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
        );
        break;
      case 'fade':
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
        _scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(_animationController);
        break;
      case 'slide':
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
        _scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(_animationController);
        break;
      default:
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
        _scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(_animationController);
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return Colors.blue; // fallback
    } catch (e) {
      return Colors.blue; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parseColor(EnvConfig.splashBgColor),
      body: Container(
        decoration: EnvConfig.splashBgUrl.isNotEmpty
            ? BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(EnvConfig.splashBgUrl),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      if (EnvConfig.splashUrl.isNotEmpty)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: EnvConfig.splashUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      // Tagline
                      if (EnvConfig.splashTagline.isNotEmpty)
                        Text(
                          EnvConfig.splashTagline,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _parseColor(EnvConfig.splashTaglineColor),
                            fontFamily: EnvConfig.bottommenuFont,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Loading indicator
                      if (EnvConfig.isLoadInd)
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _parseColor(EnvConfig.splashTaglineColor),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
