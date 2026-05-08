class WerewolfRole {
  final int id;
  final String name;
  final int points;
  final int allianceId;
  final String description;
  final String imagePath;
  final String translationKey;
  final String descriptionKey;

  WerewolfRole({
    required this.id,
    required this.name,
    required this.points,
    required this.allianceId,
    required this.description,
    required this.imagePath,
    required this.translationKey,
    required this.descriptionKey,
  });
}

class WerewolfRoleService {
  static final List<WerewolfRole> _roles = [
    WerewolfRole(
      id: 1,
      name: 'Villager',
      points: 1,
      allianceId: 1, // Villagers
      description: 'A simple townsperson trying to survive the night.',
      imagePath: 'assets/images/werewolves/Villager.png',
      translationKey: 'villager_name',
      descriptionKey: 'villager_desc',
    ),
    WerewolfRole(
      id: 2,
      name: 'Werewolf',
      points: 2,
      allianceId: 2, // Werewolves
      description:
          'A fierce predator hungry for villagers. Each night, they can kill one player. Wins if they outnumber the village.',
      imagePath: 'assets/images/werewolves/Werewolf.png',
      translationKey: 'werewolf_name',
      descriptionKey: 'werewolf_desc',
    ),
    WerewolfRole(
      id: 3,
      name: 'Doctor',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A dedicated healer. Each night, she can save one person from being attacked that night.',
      imagePath: 'assets/images/werewolves/Doctor.png',
      translationKey: 'doctor_name',
      descriptionKey: 'doctor_desc',
    ),
    WerewolfRole(
      id: 4,
      name: 'Guard',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A vigilant protector. Each night, he can inspect one player.',
      imagePath: 'assets/images/werewolves/Guard.png',
      translationKey: 'guard_name',
      descriptionKey: 'guard_desc',
    ),
    WerewolfRole(
      id: 5,
      name: 'Plague Doctor',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A mysterious healer. Each night, he can save one player but also has a small chance to kill him.',
      imagePath: 'assets/images/werewolves/Plague Doctor.png',
      translationKey: 'plague_doctor_name',
      descriptionKey: 'plague_doctor_desc',
    ),
    WerewolfRole(
      id: 6,
      name: 'Twins',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'Two souls bound together. If one is hanged by the village, the other turns into a werewolf. if one is killed by a werewolf, the other remains a villager.',
      imagePath: 'assets/images/werewolves/Twins.png',
      translationKey: 'twins_name',
      descriptionKey: 'twins_desc',
    ),
    WerewolfRole(
      id: 7,
      name: 'Avenging Twin',
      points: 3,
      allianceId: 2, // Werewolves
      description:
          'A twin fueled by vengeance. When their sibling is hanged by the village, they embrace the darkness and join the werewolves to hunt down those who killed their loved one.',
      imagePath: 'assets/images/werewolves/Avenging Twin.png',
      translationKey: 'avenging_twin_name',
      descriptionKey: 'avenging_twin_desc',
    ),
    WerewolfRole(
      id: 8,
      name: 'Vampire',
      points: 2,
      allianceId: 2, // Werewolves
      description:
          'A dark creature of the night. Awakens and kills with the werewolves each night, but remains undetected by the Guard.',
      imagePath: 'assets/images/werewolves/Vampire.png',
      translationKey: 'vampire_name',
      descriptionKey: 'vampire_desc',
    ),
    WerewolfRole(
      id: 9,
      name: 'Jester',
      points: 3,
      allianceId: 3, // Jester
      description:
          'A silly trickster. Wants to be hanged by the village to claim victory.',
      imagePath: 'assets/images/werewolves/Jester.png',
      translationKey: 'jester_name',
      descriptionKey: 'jester_desc',
    ),
    WerewolfRole(
      id: 10,
      name: 'Drunk',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A confused townsperson who appears as a Werewolf to the Guard, but is actually a Villager.',
      imagePath: 'assets/images/werewolves/Drunk.png',
      translationKey: 'drunk_name',
      descriptionKey: 'drunk_desc',
    ),
    WerewolfRole(
      id: 11,
      name: 'Knight',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A brave warrior. He has armor that protects him from the first lethal attack. He only dies if attacked a second time.',
      imagePath: 'assets/images/werewolves/Knight.png',
      translationKey: 'knight_name',
      descriptionKey: 'knight_desc',
    ),
    WerewolfRole(
      id: 12,
      name: 'Puppet Master',
      points: 0,
      allianceId: 3, // Specials
      description:
          'A mysterious observer. Transforms into the role of the first person who gets hanged by the village.',
      imagePath: 'assets/images/werewolves/Puppet Master.png',
      translationKey: 'puppet_master_name',
      descriptionKey: 'puppet_master_desc',
    ),
    WerewolfRole(
      id: 13,
      name: 'Executioner',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A vengeful villager. If hanged by the village, he can take one player with him to the grave.',
      imagePath: 'assets/images/werewolves/Executioner.png',
      translationKey: 'executioner_name',
      descriptionKey: 'executioner_desc',
    ),
    WerewolfRole(
      id: 14,
      name: 'Infected',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A simple villager but carrying a hidden disease. If the Doctor heals them, the Doctor gets infected and dies. If the werewolves target her at night while they have a vampire in their team, the vampire gets infected and dies too.',
      imagePath: 'assets/images/werewolves/Infected.png',
      translationKey: 'infected_name',
      descriptionKey: 'infected_desc',
    ),
    WerewolfRole(
      id: 15,
      name: 'Gambler',
      points:
          0, // Points are determined by bet outcome: +1 Village, +2 Werewolves, +3 Specials
      allianceId: 3, // Specials
      description:
          'A cunning risk-taker who bets on fate. On the first night, they secretly choose which alliance they believe will win. If correct, they share in the victory points. Behaves as a normal villager otherwise.',
      imagePath: 'assets/images/werewolves/Gambler.png',
      translationKey: 'gambler_name',
      descriptionKey: 'gambler_desc',
    ),
    WerewolfRole(
      id: 16,
      name: 'Shaman',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A mystical seer who communes with the spirits. Every second night, the Shaman can inspect one player and learn their true role. Unlike the Guard, the Shaman sees through all disguises.',
      imagePath: 'assets/images/werewolves/Shaman.png',
      translationKey: 'shaman_name',
      descriptionKey: 'shaman_desc',
    ),
    WerewolfRole(
      id: 17,
      name: 'Wraith',
      points: 1,
      allianceId: 1, // Villagers
      description:
          'A restless spirit bound to the village. The Wraith cannot be killed by any means — not by werewolves, plague, hanging, or execution. It lingers eternally, watching over the living.',
      imagePath: 'assets/images/werewolves/Wraith.png',
      translationKey: 'wraith_name',
      descriptionKey: 'wraith_desc',
    ),
    WerewolfRole(
      id: 18,
      name: 'Dire Wolf',
      points: 2,
      allianceId: 2, // Werewolves
      description:
          'A terrifying alpha predator. Hunts with the pack, then wakes alone every other night to silence one player, preventing them from using their ability the following night.',
      imagePath: 'assets/images/werewolves/Dire Wolf.png',
      translationKey: 'dire_wolf_name',
      descriptionKey: 'dire_wolf_desc',
    ),
  ];

  List<WerewolfRole> getRoles() => _roles;

  WerewolfRole? getRoleById(int id) {
    try {
      return _roles.firstWhere((role) => role.id == id);
    } catch (_) {
      return null;
    }
  }

  List<WerewolfRole> getRolesByAlliance(int allianceId) {
    return _roles.where((role) => role.allianceId == allianceId).toList();
  }
}
