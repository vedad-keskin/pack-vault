class WerewolfAlliance {
  final int id;
  final String name;
  final String description;
  final String translationKey;
  final String descriptionKey;

  WerewolfAlliance({
    required this.id,
    required this.name,
    required this.description,
    required this.translationKey,
    required this.descriptionKey,
  });
}

class WerewolfAllianceService {
  static final List<WerewolfAlliance> _alliances = [
    WerewolfAlliance(
      id: 1,
      name: 'Villagers',
      description:
          'The peaceful inhabitants of the village. Their goal is to find and eliminate all werewolves.',
      translationKey: 'villagers_alliance_name',
      descriptionKey: 'villagers_alliance_desc',
    ),
    WerewolfAlliance(
      id: 2,
      name: 'Werewolves',
      description:
          'The predators of the night. Their goal is to outnumber the villagers to take over the town.',
      translationKey: 'werewolves_alliance_name',
      descriptionKey: 'werewolves_alliance_desc',
    ),
    WerewolfAlliance(
      id: 3,
      name: 'Specials',
      description:
          'Independent roles with unique win conditions and special abilities.',
      translationKey: 'specials_alliance_name',
      descriptionKey: 'specials_alliance_desc',
    ),
  ];

  List<WerewolfAlliance> getAlliances() => _alliances;

  WerewolfAlliance? getAllianceById(int id) {
    try {
      return _alliances.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
