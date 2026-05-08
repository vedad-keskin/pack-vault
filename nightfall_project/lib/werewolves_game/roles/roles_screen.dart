import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightfall_project/base_components/pixel_starfield_background.dart';
import 'package:nightfall_project/base_components/pixel_button.dart';
import 'package:nightfall_project/werewolves_game/offline_db/role_service.dart';
import 'package:nightfall_project/werewolves_game/offline_db/alliance_service.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:provider/provider.dart';

enum RoleAllianceFilter { all, village, werewolves, specials }

class WerewolfRolesScreen extends StatefulWidget {
  const WerewolfRolesScreen({super.key});

  @override
  State<WerewolfRolesScreen> createState() => _WerewolfRolesScreenState();
}

class _WerewolfRolesScreenState extends State<WerewolfRolesScreen> {
  final WerewolfRoleService _roleService = WerewolfRoleService();
  final WerewolfAllianceService _allianceService = WerewolfAllianceService();
  late List<WerewolfRole> _allRoles;
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  RoleAllianceFilter _selectedFilter = RoleAllianceFilter.all;

  // Track flip state by role id so it remains stable when filtering
  final Map<int, bool> _isFlippedByRoleId = {};

  @override
  void initState() {
    super.initState();
    _allRoles = _roleService.getRoles();
    for (final role in _allRoles) {
      _isFlippedByRoleId[role.id] = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getAllianceColor(int allianceId) {
    switch (allianceId) {
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.redAccent;
      case 3:
        return Colors.purpleAccent;
      default:
        return Colors.white;
    }
  }

  List<WerewolfRole> get _filteredRoles {
    switch (_selectedFilter) {
      case RoleAllianceFilter.village:
        return _allRoles.where((role) => role.allianceId == 1).toList();
      case RoleAllianceFilter.werewolves:
        return _allRoles.where((role) => role.allianceId == 2).toList();
      case RoleAllianceFilter.specials:
        return _allRoles.where((role) => role.allianceId == 3).toList();
      case RoleAllianceFilter.all:
        return _allRoles;
    }
  }

  Color _getFilterColor(RoleAllianceFilter filter) {
    switch (filter) {
      case RoleAllianceFilter.all:
        return const Color(0xFF778DA9);
      case RoleAllianceFilter.village:
        return _getAllianceColor(1);
      case RoleAllianceFilter.werewolves:
        return _getAllianceColor(2);
      case RoleAllianceFilter.specials:
        return _getAllianceColor(3);
    }
  }

  int? _getAllianceIdForFilter(RoleAllianceFilter filter) {
    switch (filter) {
      case RoleAllianceFilter.village:
        return 1;
      case RoleAllianceFilter.werewolves:
        return 2;
      case RoleAllianceFilter.specials:
        return 3;
      case RoleAllianceFilter.all:
        return null;
    }
  }

  String _getFilterLabel(
    RoleAllianceFilter filter,
    LanguageService languageService,
  ) {
    switch (filter) {
      case RoleAllianceFilter.all:
        return languageService.translate('all_label').toUpperCase();
      case RoleAllianceFilter.village:
        return languageService
            .translate('villagers_alliance_name')
            .toUpperCase();
      case RoleAllianceFilter.werewolves:
        return languageService
            .translate('werewolves_alliance_name')
            .toUpperCase();
      case RoleAllianceFilter.specials:
        return languageService
            .translate('specials_alliance_name')
            .toUpperCase();
    }
  }

  void _setFilter(RoleAllianceFilter filter) {
    setState(() {
      // Toggle: if same filter clicked again, clear to "all"
      _selectedFilter = _selectedFilter == filter ? RoleAllianceFilter.all : filter;
      _currentPage = 0;
      _isFlippedByRoleId.updateAll((_, __) => false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  Widget _buildAllianceFilterBar(
    LanguageService languageService,
    int? currentRoleAllianceId,
  ) {
    // Only three tiles; "all" is default when none selected
    final filters = [
      RoleAllianceFilter.werewolves,
      RoleAllianceFilter.village,
      RoleAllianceFilter.specials,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A).withValues(alpha: 0.85),
          border: Border.all(color: const Color(0xFF415A77), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < filters.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: _buildFilterTab(
                  filters[i],
                  languageService,
                  currentRoleAllianceId: currentRoleAllianceId,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(
    RoleAllianceFilter filter,
    LanguageService languageService, {
    int? currentRoleAllianceId,
  }) {
    final isSelected = _selectedFilter == filter;
    final baseColor = _getFilterColor(filter);
    // In "all" mode: light only the dot for the tile matching current card's alliance
    final allianceId = _getAllianceIdForFilter(filter);
    final dotOn = isSelected ||
        (currentRoleAllianceId != null && currentRoleAllianceId == allianceId);

    return GestureDetector(
      onTap: () => _setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? baseColor.withValues(alpha: 0.25)
              : const Color(0xFF1B263B).withValues(alpha: 0.5),
          border: Border.all(
            color: isSelected ? baseColor : const Color(0xFF415A77),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 4),
                  color: dotOn
                      ? baseColor
                      : const Color(0xFFE0E1DD).withValues(alpha: 0.4),
                ),
                Text(
                  _getFilterLabel(filter, languageService),
                  style: GoogleFonts.vt323(
                    color: isSelected
                        ? const Color(0xFFE0E1DD)
                        : const Color(0xFFE0E1DD).withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final filteredRoles = _filteredRoles;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const PixelStarfieldBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      PixelButton(
                        label: languageService.translate('back'),
                        color: const Color(0xFF415A77),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Center(
                          child: Text(
                            languageService.translate('roles_title'),
                            style: GoogleFonts.pressStart2p(
                              color: const Color(0xFFE0E1DD),
                              fontSize: 24,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 80),
                    ],
                  ),
                ),

                _buildAllianceFilterBar(
                  languageService,
                  _selectedFilter == RoleAllianceFilter.all &&
                          _filteredRoles.isNotEmpty
                      ? _filteredRoles[
                              _currentPage.clamp(0, _filteredRoles.length - 1)]
                          .allianceId
                      : null,
                ),
                const SizedBox(height: 14),

                // Swipable Cards
                Expanded(
                  child: filteredRoles.isEmpty
                      ? Center(
                          child: Text(
                            'NO ROLES',
                            style: GoogleFonts.pressStart2p(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                              _isFlippedByRoleId.updateAll((_, __) => false);
                            });
                          },
                          itemCount: filteredRoles.length,
                          itemBuilder: (context, index) {
                            final role = filteredRoles[index];
                            final isSelected = index == _currentPage;
                            final isFlipped =
                                _isFlippedByRoleId[role.id] ?? false;

                            return AnimatedScale(
                              duration: const Duration(milliseconds: 300),
                              scale: isSelected ? 1.0 : 0.8,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isSelected ? 1.0 : 0.5,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isFlippedByRoleId[role.id] = !isFlipped;
                                    });
                                  },
                                  child: Center(
                                    child: AspectRatio(
                                      aspectRatio: 880 / 1184,
                                      child: TweenAnimationBuilder(
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        curve: Curves.easeInOutBack,
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: isFlipped ? 180 : 0,
                                        ),
                                        builder:
                                            (context, double value, child) {
                                              final isBack = value > 90;
                                              return Transform(
                                                transform: Matrix4.identity()
                                                  ..setEntry(3, 2, 0.001)
                                                  ..rotateY(value * pi / 180),
                                                alignment: Alignment.center,
                                                child: isBack
                                                    ? Transform(
                                                        transform:
                                                            Matrix4.identity()
                                                              ..rotateY(pi),
                                                        alignment:
                                                            Alignment.center,
                                                        child: _buildCardBack(
                                                          role,
                                                        ),
                                                      )
                                                    : _buildCardFront(role),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Indicator
                if (filteredRoles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        filteredRoles.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: index == _currentPage
                                ? const Color(0xFFE0E1DD)
                                : const Color(0xFF415A77),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (filteredRoles.isNotEmpty)
                  Text(
                    languageService.translate('tap_to_flip_card'),
                    style: GoogleFonts.vt323(
                      color: Colors.white38,
                      fontSize: 20,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(WerewolfRole role) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF778DA9), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(10, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(role.imagePath, fit: BoxFit.cover),
          // Name Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Text(
                context
                    .watch<LanguageService>()
                    .translate(role.translationKey)
                    .toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(WerewolfRole role) {
    final alliance = _allianceService.getAllianceById(role.allianceId);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF778DA9),
        border: Border.all(color: const Color(0xFF415A77), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(10, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          border: Border.all(color: Colors.black, width: 4),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              context
                  .watch<LanguageService>()
                  .translate(role.translationKey)
                  .toUpperCase(),
              style: GoogleFonts.pressStart2p(
                color: const Color(0xFFE0E1DD),
                fontSize: 18,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(height: 4, width: 100, color: const Color(0xFF415A77)),
            const SizedBox(height: 20),

            // Scrollable Content Region
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Alliance
                    Text(
                      context.watch<LanguageService>().translate(
                        'alliance_label',
                      ),
                      style: GoogleFonts.vt323(
                        color: Colors.white54,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      context
                          .watch<LanguageService>()
                          .translate(alliance?.translationKey ?? 'UNKNOWN')
                          .toUpperCase(),
                      style: GoogleFonts.vt323(
                        color: _getAllianceColor(role.allianceId),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text(
                      context.watch<LanguageService>().translate(
                        role.descriptionKey,
                      ),
                      style: GoogleFonts.vt323(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Fixed Win Points at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    context
                        .watch<LanguageService>()
                        .translate('win_pts_label')
                        .replaceAll(
                          '{points}',
                          role.points == 0 ? "?" : role.points.toString(),
                        ),
                    style: GoogleFonts.pressStart2p(
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
