import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/language_service.dart';

class PixelLanguageSwitch extends StatefulWidget {
  const PixelLanguageSwitch({super.key});

  @override
  State<PixelLanguageSwitch> createState() => _PixelLanguageSwitchState();
}

class _PixelLanguageSwitchState extends State<PixelLanguageSwitch> {
  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isEn = languageService.currentLanguage == 'en';

    return GestureDetector(
      onTap: () {
        languageService.setLanguage(isEn ? 'bs' : 'en');
      },
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B263B), // Darker Navy
            border: Border.all(color: const Color(0xFF415A77), width: 2),
          ),
          child: Stack(
            children: [
              // Sliding Highlight
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isEn ? 0 : 44, // 100 - padding(8) - width(44) = 48?
                top: 0,
                bottom: 0,
                width: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF778DA9),
                    border: Border.all(
                      color: const Color(0xFFE0E1DD),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2,
                        left: 2,
                        right: 2,
                        height: 2,
                        child: Container(color: Colors.white24),
                      ),
                    ],
                  ),
                ),
              ),
              // Flags
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: isEn ? 1.0 : 0.3,
                        child: Image.asset(
                          'assets/images/uk.png',
                          width: 28,
                          height: 20,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: !isEn ? 1.0 : 0.3,
                        child: Image.asset(
                          'assets/images/bih.png',
                          width: 28,
                          height: 20,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
