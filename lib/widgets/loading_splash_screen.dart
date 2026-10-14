import 'package:flutter/material.dart';

/// Branded loading screen used while startup or the initial home data loads.
class LoadingSplashScreen extends StatelessWidget {
  const LoadingSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF006238),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: AssetImage('assets/branding/splash_screen_mobile.png'),
            fit: BoxFit.contain,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFFFCC00),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
