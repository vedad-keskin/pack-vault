import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';

/// Represents the alliance the Gambler bet on
enum GamblerBet {
  village, // +1 point if Village wins
  werewolves, // +2 points if Werewolves win
  specials, // +3 points if Specials (Jester) wins
}

class GamblerBetDialog extends StatefulWidget {
  final String playerName;
  final Function(GamblerBet) onBetConfirmed;

  const GamblerBetDialog({
    super.key,
    required this.playerName,
    required this.onBetConfirmed,
  });

  @override
  State<GamblerBetDialog> createState() => _GamblerBetDialogState();
}

class _GamblerBetDialogState extends State<GamblerBetDialog>
    with TickerProviderStateMixin {
  // Default to village selected
  GamblerBet _selectedBet = GamblerBet.village;
  bool _isRolling = false;
  bool _betConfirmed = false;
  final Random _random = Random();

  // Carousel state
  late PageController _pageController;
  int _currentPageIndex = 0;
  final List<GamblerBet> _bets = [
    GamblerBet.village,
    GamblerBet.werewolves,
    GamblerBet.specials,
  ];

  // Animation Controllers
  late AnimationController _entranceController;
  late AnimationController _diceController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _confirmationController;
  late AnimationController _runeController;

  // Animations
  late Animation<double> _entranceScale;
  late Animation<double> _entranceFade;

  // Dice face values for animation
  int _dice1 = 1;
  int _dice2 = 1;

  // Individual dice animation offsets for natural feel
  double _dice1RotationOffset = 0;
  double _dice2RotationOffset = 0;
  double _dice1BouncePhase = 0;
  double _dice2BouncePhase = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);

    // Randomize dice animation offsets
    _dice1RotationOffset = _random.nextDouble() * pi;
    _dice2RotationOffset = _random.nextDouble() * pi + pi / 2;
    _dice1BouncePhase = _random.nextDouble() * pi;
    _dice2BouncePhase = _random.nextDouble() * pi + pi / 3;

    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Entrance animation - dramatic reveal
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entranceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Dice rolling
    _diceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _diceController.addListener(_onDiceRoll);

    // Glow pulsing for selected card
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // General pulse for UI elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Confirmation explosion
    _confirmationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Card rune rotation
    _runeController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Start entrance animation
    _entranceController.forward();
  }

  void _onDiceRoll() {
    if (_isRolling) {
      setState(() {
        _dice1 = _random.nextInt(6) + 1;
        _dice2 = _random.nextInt(6) + 1;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _diceController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _confirmationController.dispose();
    _runeController.dispose();
    super.dispose();
  }

  Future<void> _playDiceSound() async {
    if (context.read<SoundSettingsService>().isMuted) return;
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('audio/werewolves/dice_roll.mp3'));
    } catch (e) {
      debugPrint('Dice sound not available: $e');
    }
  }

  Future<void> _confirmBet() async {
    setState(() {
      _isRolling = true;
    });

    _playDiceSound();
    _diceController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _isRolling = false;
      _betConfirmed = true;
    });

    _confirmationController.forward();

    await Future.delayed(const Duration(milliseconds: 2500));

    widget.onBetConfirmed(_selectedBet);
  }

  Color _getBetColor(GamblerBet bet) {
    switch (bet) {
      case GamblerBet.village:
        return const Color(0xFF52B788);
      case GamblerBet.werewolves:
        return const Color(0xFFE63946);
      case GamblerBet.specials:
        return const Color(0xFF9D4EDD);
    }
  }

  String _getBetLabel(GamblerBet bet) {
    final lang = context.read<LanguageService>();
    switch (bet) {
      case GamblerBet.village:
        return lang.translate('gambler_bet_village');
      case GamblerBet.werewolves:
        return lang.translate('gambler_bet_werewolves');
      case GamblerBet.specials:
        return lang.translate('gambler_bet_specials');
    }
  }

  String _getBetReward(GamblerBet bet) {
    final lang = context.read<LanguageService>();
    switch (bet) {
      case GamblerBet.village:
        return lang.translate('gambler_village_reward');
      case GamblerBet.werewolves:
        return lang.translate('gambler_werewolves_reward');
      case GamblerBet.specials:
        return lang.translate('gambler_specials_reward');
    }
  }

  String _getBetIcon(GamblerBet bet) {
    switch (bet) {
      case GamblerBet.village:
        return 'assets/images/gambler_village.png';
      case GamblerBet.werewolves:
        return 'assets/images/gambler_werewolves.png';
      case GamblerBet.specials:
        return 'assets/images/gambler_specials.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.scale(
          scale: _entranceScale.value,
          child: Opacity(
            opacity: _entranceFade.value.clamp(0.0, 1.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: _buildMainContent(lang),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(LanguageService lang) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF415A77), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(lang),
          const SizedBox(height: 16),
          _buildDiceSection(),
          const SizedBox(height: 20),
          if (!_betConfirmed) ...[
            _buildCarousel(),
            const SizedBox(height: 20),
            _buildConfirmButton(),
          ] else
            _buildConfirmedBetDisplay(),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService lang) {
    return Column(
      children: [
        _buildOrnateDivider(),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFFD4AF37).withOpacity(0.5),
                    const Color(0xFFFFD700),
                    _glowController.value,
                  )!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFD4AF37,
                    ).withOpacity(0.1 + _glowController.value * 0.15),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.playerName.toUpperCase(),
                style: GoogleFonts.cinzelDecorative(
                  color: const Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                const Color(0xFFD4AF37),
                const Color(0xFFFFD700),
                const Color(0xFFD4AF37),
              ],
              stops: [0.0, _pulseController.value, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            lang.translate('gambler_bet_title'),
            style: GoogleFonts.pressStart2p(
              color: Colors.white,
              fontSize: 12,
              shadows: [
                const Shadow(color: Colors.black, offset: Offset(2, 2)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lang.translate('gambler_bet_subtitle'),
          style: GoogleFonts.vt323(color: Colors.white60, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrnateDivider() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final goldColor = Color.lerp(
          const Color(0xFFD4AF37),
          const Color(0xFFFFD700),
          _pulseController.value,
        )!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: goldColor,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 40,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goldColor.withOpacity(0), goldColor],
                ),
              ),
            ),
            Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: goldColor,
                  border: Border.all(color: const Color(0xFF8B6914), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 40,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goldColor, goldColor.withOpacity(0)],
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: goldColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDice(_dice1, _dice1RotationOffset, _dice1BouncePhase),
        const SizedBox(width: 20),
        _buildDice(_dice2, _dice2RotationOffset, _dice2BouncePhase),
      ],
    );
  }

  Widget _buildDice(int value, double rotationOffset, double bouncePhase) {
    return AnimatedBuilder(
      animation: _diceController,
      builder: (context, child) {
        final progress = _diceController.value;
        final easedProgress = Curves.easeOutQuart.transform(progress);

        double bounceY = 0;
        double horizontalShake = 0;

        if (_isRolling) {
          final bounce1 =
              sin((progress * 5 + bouncePhase) * pi) *
              12 *
              pow(1 - progress, 1.5);
          final bounce2 =
              sin((progress * 12 + bouncePhase) * pi) *
              4 *
              pow(1 - progress, 2);
          bounceY = (bounce1.abs() + bounce2.abs());
          horizontalShake =
              sin((progress * 8 + rotationOffset) * pi) *
              3 *
              (1 - easedProgress);
        }

        final rotationSpeed = _isRolling ? (1 - easedProgress) : 0.0;
        final rotateX = _isRolling
            ? (progress * 6 + rotationOffset) * pi * rotationSpeed +
                  rotationOffset
            : 0.0;
        final rotateY = _isRolling
            ? (progress * 4 + rotationOffset * 0.7) * pi * rotationSpeed
            : 0.0;
        final rotateZ = _isRolling
            ? (progress * 3 + rotationOffset * 0.5) * pi * rotationSpeed * 0.5
            : 0.0;

        double scale = 1.0;
        if (_isRolling) {
          final squash =
              1.0 -
              sin(progress * pi * 5 + bouncePhase).abs() * 0.1 * (1 - progress);
          scale = squash;
        }

        final settleTiltX = _isRolling
            ? sin(rotationOffset) * 0.05 * easedProgress
            : sin(rotationOffset) * 0.03;
        final settleTiltZ = _isRolling
            ? cos(rotationOffset) * 0.04 * easedProgress
            : cos(rotationOffset) * 0.02;

        return Transform.translate(
          offset: Offset(horizontalShake, -bounceY),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.003)
              ..rotateX(rotateX + settleTiltX)
              ..rotateY(rotateY)
              ..rotateZ(rotateZ + settleTiltZ)
              ..scale(scale, scale * (1 + bounceY * 0.01)),
            alignment: Alignment.center,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    const Color(0xFFFFFEFA),
                    const Color(0xFFF8F3E6),
                    const Color(0xFFF0E8D5),
                    const Color(0xFFE5DBC5),
                  ],
                ),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFF4A3520), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4 + bounceY * 0.02),
                    offset: Offset(
                      2 + horizontalShake * 0.3,
                      2 + bounceY * 0.15,
                    ),
                    blurRadius: 1 + bounceY * 0.2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: Offset(0, 4 + bounceY * 0.5),
                    blurRadius: 4 + bounceY * 0.3,
                    spreadRadius: bounceY * 0.1,
                  ),
                  if (_isRolling)
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _buildDiceFace(value),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiceFace(int value) {
    List<Alignment> dots = [];
    switch (value) {
      case 1:
        dots = [Alignment.center];
        break;
      case 2:
        dots = [const Alignment(-0.7, -0.7), const Alignment(0.7, 0.7)];
        break;
      case 3:
        dots = [
          const Alignment(-0.7, -0.7),
          Alignment.center,
          const Alignment(0.7, 0.7),
        ];
        break;
      case 4:
        dots = [
          const Alignment(-0.7, -0.7),
          const Alignment(0.7, -0.7),
          const Alignment(-0.7, 0.7),
          const Alignment(0.7, 0.7),
        ];
        break;
      case 5:
        dots = [
          const Alignment(-0.7, -0.7),
          const Alignment(0.7, -0.7),
          Alignment.center,
          const Alignment(-0.7, 0.7),
          const Alignment(0.7, 0.7),
        ];
        break;
      case 6:
        dots = [
          const Alignment(-0.7, -0.7),
          const Alignment(0.7, -0.7),
          const Alignment(-0.7, 0.0),
          const Alignment(0.7, 0.0),
          const Alignment(-0.7, 0.7),
          const Alignment(0.7, 0.7),
        ];
        break;
    }

    return Stack(
      children: dots.map((alignment) {
        return Align(
          alignment: alignment,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [const Color(0xFF3D2815), const Color(0xFF1A0F08)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(0.5, 0.5),
                  blurRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
                _selectedBet = _bets[index];
              });
            },
            itemCount: _bets.length,
            itemBuilder: (context, index) {
              return _buildCarouselCard(_bets[index], index);
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildPageIndicators(),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.4 + _pulseController.value * 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chevron_left,
                    color: Color(0xFFD4AF37),
                    size: 14,
                  ),
                  Text(
                    'SWIPE',
                    style: GoogleFonts.vt323(
                      color: const Color(0xFFD4AF37),
                      fontSize: 12,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFD4AF37),
                    size: 14,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_bets.length, (index) {
        final bet = _bets[index];
        final isCurrentPage = index == _currentPageIndex;
        final color = _getBetColor(bet);

        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isCurrentPage ? 12 : 8,
            height: isCurrentPage ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrentPage ? color : const Color(0xFF415A77),
              border: Border.all(
                color: isCurrentPage ? Colors.white : const Color(0xFF415A77),
                width: 2,
              ),
              boxShadow: isCurrentPage
                  ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCarouselCard(GamblerBet bet, int index) {
    final isSelected = _selectedBet == bet;
    final isCurrent = index == _currentPageIndex;
    final color = _getBetColor(bet);

    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _runeController]),
      builder: (context, child) {
        return AnimatedScale(
          scale: isCurrent ? 1.0 : 0.85,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isCurrent ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning rune circle behind the card
                  if (isCurrent)
                    Transform.rotate(
                      angle: _runeController.value * 2 * pi,
                      child: CustomPaint(
                        size: const Size(220, 220),
                        painter: _CardRunePainter(
                          color: color.withOpacity(
                            0.2 + _glowController.value * 0.1,
                          ),
                        ),
                      ),
                    ),
                  // Card content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(isSelected ? 0.4 : 0.2),
                          color.withOpacity(isSelected ? 0.2 : 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? color : color.withOpacity(0.5),
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.white : color,
                              width: 4,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(
                                        0.4 + _glowController.value * 0.3,
                                      ),
                                      blurRadius:
                                          15 + _glowController.value * 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            // Slightly smaller to account for the border width
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              _getBetIcon(bet),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Alliance name
                        Text(
                          _getBetLabel(bet),
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Reward badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getBetReward(bet),
                            style: GoogleFonts.pressStart2p(
                              color: Colors.amber,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: !_isRolling ? _confirmBet : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  const Color(0xFF8B6914).withOpacity(0.3),
                ],
              ),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFFD4AF37),
                  const Color(0xFFFFD700),
                  _pulseController.value,
                )!,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFD4AF37,
                  ).withOpacity(0.2 + _pulseController.value * 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedRotation(
                  turns: _isRolling ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Icon(
                    _isRolling ? Icons.casino : Icons.casino_outlined,
                    color: const Color(0xFFD4AF37),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRolling
                      ? '...'
                      : context.read<LanguageService>().translate(
                          'gambler_roll_dice',
                        ),
                  style: GoogleFonts.pressStart2p(
                    color: const Color(0xFFD4AF37),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmedBetDisplay() {
    final color = _getBetColor(_selectedBet);

    return AnimatedBuilder(
      animation: _confirmationController,
      builder: (context, child) {
        final scale = Curves.elasticOut.transform(
          _confirmationController.value.clamp(0.0, 1.0),
        );

        return Transform.scale(
          scale: scale,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(8, (index) {
                    return Transform.rotate(
                      angle:
                          index * pi / 4 + _confirmationController.value * pi,
                      child: Container(
                        width: 4,
                        height: 70 * _confirmationController.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          color.withOpacity(0.4),
                          color.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(color: color, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Transform.rotate(
                                angle: (1 - value) * pi,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.6),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(17),
                                    child: Image.asset(
                                      _getBetIcon(_selectedBet),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getBetLabel(_selectedBet),
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.bounceOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.3),
                                  border: Border.all(
                                    color: Colors.amber,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  _getBetReward(_selectedBet),
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.amber,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<int>(
                tween: IntTween(
                  begin: 0,
                  end: context
                      .read<LanguageService>()
                      .translate('gambler_fate_sealed')
                      .length,
                ),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  final text = context.read<LanguageService>().translate(
                    'gambler_fate_sealed',
                  );
                  return Text(
                    text.substring(0, value),
                    style: GoogleFonts.pressStart2p(
                      color: const Color(0xFFD4AF37),
                      fontSize: 9,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom painter for spinning rune circle behind cards
class _CardRunePainter extends CustomPainter {
  final Color color;
  _CardRunePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw concentric circles
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.75, paint);

    // Draw connecting lines and diamond markers
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final x1 = center.dx + cos(angle) * (radius - 5);
      final y1 = center.dy + sin(angle) * (radius - 5);
      final x2 = center.dx + cos(angle) * (radius * 0.75 + 5);
      final y2 = center.dy + sin(angle) * (radius * 0.75 + 5);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

      // Diamond marker at outer edge
      final path = Path()
        ..moveTo(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius - 4,
        )
        ..lineTo(
          center.dx + cos(angle) * radius + 3,
          center.dy + sin(angle) * radius,
        )
        ..lineTo(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius + 4,
        )
        ..lineTo(
          center.dx + cos(angle) * radius - 3,
          center.dy + sin(angle) * radius,
        )
        ..close();
      canvas.drawPath(path, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _CardRunePainter oldDelegate) =>
      oldDelegate.color != color;
}
