const Map<String, String> enTranslations = {
  'werewolves': 'WEREWOLVES',
  'impostor': 'IMPOSTOR',
  'impostor-game': 'IMPOSTOR GAME',
  'impostor-player': "IMPOSTOR",
  'play_now': 'PLAY NOW',
  'back': 'BACK',
  'players_title': 'PLAYERS',
  'categories_title': 'CATEGORIES',
  'leaderboards_title': 'LEADERBOARDS',
  'hints_title': 'HINTS',
  'on': 'ON',
  'off': 'OFF',
  'game_on': 'START GAME',
  'need_at_least_3_players': 'NEED AT LEAST 3 PLAYERS',
  'need_at_least_5_players': 'NEED AT LEAST 5 PLAYERS',
  'need_players_error': 'Need at least 3 players!',
  'no_categories_error': 'No categories selected!',
  'no_words_error': 'Selected category has no words!',
  'words_available': 'words available',
  'enter_name_hint': 'Enter name...',
  'add_button': 'ADD',
  'edit_name_title': 'EDIT NAME',
  'save_button': 'SAVE',
  'cancel_button': 'CANCEL',
  'select_categories_title': 'SELECT CATEGORIES',
  'words_count': 'words',
  'pass_device_title': 'PASS THE DEVICE',
  'waiting_players': 'Waiting for all players...',
  'game_start': 'GAME START',
  'secret_role': 'SECRET ROLE',
  'top_secret': 'TOP SECRET',
  'tap_to_flip': 'TAP TO FLIP',
  'understood_button': 'UNDERSTOOD',
  'you_are_the': 'YOU ARE THE',
  'word_is': 'THE WORD IS:',
  'category_label': 'CATEGORY:',
  'hint_label': 'HINT:',
  'discussion_time': 'DISCUSSION TIME',
  'inst_1': 'Go around in a circle for 2 or 3 rounds.',
  'inst_2': 'Each player must say ONE WORD related to their secret.',
  'inst_3': 'After rounds are over, you must vote for the IMPOSTOR!',
  'starting_player_label': 'STARTING PLAYER',
  'start_voting_button': 'START VOTING',
  'who_is_impostor': 'WHO IS THE IMPOSTOR?',
  'drag_suspect_here': 'DRAG SUSPECT HERE',
  'reveal_impostor_button': 'REVEAL IMPOSTOR',
  'vote_instruction': 'Drag a player to the box to vote',
  'verdict_title': 'THE VERDICT',
  'voted_as_impostor': 'VOTED AS IMPOSTOR:',
  'verdict_innocent': 'THEY WERE INNOCENT!',
  'verdict_impostor': 'THEY WERE THE IMPOSTOR!',
  'real_impostor_was': 'THE REAL IMPOSTOR WAS:',
  'secret_word': 'SECRET WORD',
  'impostor_escaped': 'THE IMPOSTOR ESCAPED!',
  'point_to': '+1 POINT TO',
  'innocents_win': 'INNOCENTS WIN!',
  'caught_impostor': 'You caught the Impostor!',
  'back_to_menu': 'BACK TO MENU',
  'reset_points_q': 'RESET POINTS?',
  'reset_undo_warn':
      'All player points will be set to zero. This cannot be undone.',
  'reset_button': 'RESET',
  'top_players_title': 'TOP PLAYERS',
  'no_players_found': 'No players found.',
  'go_live': 'GO LIVE',
  'stop_live': 'STOP LIVE',
  'live_code_label': 'LIVE CODE',
  'live_syncing': 'SYNCING...',
  'live_confirm_stop': 'STOP LIVE SESSION?',
  'live_stop_warn': 'This will end the live session and remove data from the web. This cannot be undone.',
  'how_to_play': 'RULES',
  'rules_impostor_title': 'HOW TO PLAY: IMPOSTOR',
  'rules_impostor_content':
      '1. Setup:\n'
      'Pass the device to each player so everyone can see their role and/or word.\n\n'
      '2. Roles:\n'
      'One player is the IMPOSTOR.\n'
      'The rest are INNOCENTS.\n\n'
      '3. Secret Word:\n'
      'INNOCENTS see the secret word.\n'
      'The IMPOSTOR only sees the category and, if enabled, a hint.\n'
      'Hints are recommended for groups of 5 or fewer players. For larger groups, playing without hints is usually more fun.\n\n'
      '4. Taking Turns:\n'
      'Players take turns in a circle, starting from the player chosen first by the game.\n'
      'On your turn, say ONE word related to the secret word.\n'
      'Words that are part of the secret word are usually not allowed unless agreed on beforehand.\n'
      'If you don\'t know a word, you may Google it. The IMPOSTOR can also Google to mislead others.\n'
      'Repeating words is not allowed.\n\n'
      '5. Voting:\n'
      'After the 2nd or 3rd round, discuss and vote on who the IMPOSTOR is.\n'
      'Voting can happen earlier if INNOCENTS are confident or if the IMPOSTOR gives themselves away.\n\n'
      '6. Winning the Game:\n'
      'If the IMPOSTOR is caught, the INNOCENTS win.\n'
      'If an INNOCENT is voted out, the IMPOSTOR wins and earns a point.\n'
      'Points are tracked on the Leaderboard.\n\n'
      '7. Have Fun!\n'
      'Enjoy the game, be sneaky if you\'re the IMPOSTOR, and try to catch the IMPOSTOR if you\'re INNOCENT. Good luck!',
  'rules_werewolves_title': 'HOW TO PLAY: WEREWOLVES',
  'rules_werewolves_content':
      '1. Role Distribution:\n'
      'Pass the device to each player individually so they can view their role in secret.\n'
      'Players must confirm they have seen and understood their role before passing the device to the next player.\n\n'
      '2. Setup:\n'
      'One player needs to be the Narrator. The Narrator does not participate as a character and cannot be killed or voted out.\n'
      'The Narrator controls the flow of the game and follows instructions provided by the app.\n'
      'Players are randomly assigned roles belonging to one of the main alliances: THE VILLAGE or THE WEREWOLVES.\n'
      'Some players may receive unique special roles with additional abilities.\n\n'
      '3. Alliances and Goals:\n'
      'THE VILLAGE: Wins if all Werewolves are eliminated.\n'
      'THE WEREWOLVES: Win if they reach a point where the number of Werewolves is equal to or greater than the number of remaining Villagers.\n'
      'THE SPECIALS: They have their own special winning conditions.\n\n'
      '4. The Night Phase:\n'
      'All players close their eyes and remain silent.\n'
      'The Narrator wakes specific roles one by one, following the order shown in the app.\n'
      'When a role is awake, players use silent gestures only. To execute their ability, they point their finger at the chosen player.\n'
      'The Narrator acknowledges the choice and instructs the role to return to sleep.\n'
      'No speaking, sounds, or discussion are allowed during the Night Phase.\n\n'
      '5. The Day Phase:\n'
      'The Narrator announces the outcome of the Night (who was killed, if anyone).\n'
      'Eliminated players must remain silent for the rest of the game and may not vote.\n'
      'Discussion: All surviving players may freely discuss and accuse others.\n'
      'A discussion timer may be set when creating the game. The timer serves only as a reminder for the Narrator to move the game forward.\n'
      'Voting: Players may vote to eliminate a suspect by pointing at them.\n'
      'A player is hanged and eliminated only if they receive more than half of the votes from all living players.\n'
      'Voting may be skipped.\n'
      'If no player receives a strict majority, or in case of a tie, no player is eliminated.\n\n'
      '6. Character Abilities:\n'
      'WEREWOLF: Awakens at night with other Werewolves and collectively chooses one victim to kill.\n'
      'VILLAGER: Has no special ability. Relies on discussion, logic, and voting.\n'
      'VAMPIRE: Awakens with the Werewolves but appears as a Villager when inspected. Can be killed when targeting the Infected.\n'
      'DOCTOR: Chooses one player each night to protect from being killed.\n'
      'May protect themselves.\n'
      'Cannot protect the same player on two consecutive nights.\n'
      'GUARD: Inspects one player each night.\n'
      'The Narrator privately shows the inspection result on their device to the Guard.\n'
      'Inspection Result:\n'
      'VILLAGER – All types of Villagers, Vampires, and Jesters.\n'
      'WEREWOLF – Werewolves, Drunks, and the Avenging Twin.\n\n'
      'PLAGUE DOCTOR: Can protect one player at night, but there is a small chance the target dies instead.\n'
      'May protect themselves.\n'
      'Cannot protect the same player on two consecutive nights.\n'
      'TWINS: If one Twin is hanged during the Day Phase, the other immediately becomes a Werewolf.\n'
      'If one Twin is killed during the Night Phase, the other remains a Villager.\n'
      'AVENGING TWIN: If their Twin is hanged, they transform into an Avenging Twin.\n'
      'From the next night onward, they awaken and act with the Werewolves.\n'
      'JESTER: Wins instantly and alone if eliminated by Village vote during the Day Phase.\n'
      'DRUNK: Has no special ability and behaves as a normal Villager.\n'
      'When inspected by the Guard, the Drunk is suspicious and appears as a Werewolf.\n'
      'KNIGHT: A Villager with two lives, one protected by armor.\n'
      'First life (Armor): Cannot be healed by the Doctor or Plague Doctor.\n'
      'The armor can be destroyed by a Werewolf attack or a Plague Doctor accidental kill.\n'
      'If both attacks happen on the same night, the Knight dies immediately.\n'
      'Second life: Can be killed by Werewolves or a Plague Doctor accidental kill.\n'
      'The second life can be saved by either the Doctor or the Plague Doctor.\n'
      'Hanging kills him immediately.\n'
      'PUPPET MASTER: Starts the game as a normal Villager.\n'
      'When the first hanging of the game occurs, the Puppet Master transforms into the role of the hanged player.\n'
      'The hanged player is eliminated normally.\n'
      'If the Puppet Master is killed, nothing special happens.\n'
      'If the Jester is hanged, the Jester wins immediately and no Puppet Master transformation occurs.\n'
      'If the Gambler is hanged, the Puppet Master inherits the bet the Gambler made at the start of the game.\n'
      'If the bet is correct, both the Gambler and the Puppet Master receive the win.\n'
      'EXECUTIONER: A vengeful villager. If hanged by the village, he can take one player with him to the grave.\n'
      'INFECTED: A villager carrying a hidden sickness. If the Doctor heals them, the Doctor gets infected and dies. If she gets targeted by the Werewolves with a Vampire, a Vampire gets infected and dies too. \n'
      'GAMBLER: A cunning risk-taker who bets on fate.\n'
      'On the first night only, the Gambler is woken first and secretly chooses which alliance they believe will win.\n'
      'After placing their bet, they behave as a normal Villager for the rest of the game with no special powers.\n'
      'If the Gambler\'s chosen alliance wins, they earn bonus points: +1 for Village, +2 for Werewolves, +3 for Specials (Jester).\n'
      'The Gambler appears as a Villager when inspected by the Guard.\n'
      'SHAMAN: A mystical seer who communes with the spirits.\n'
      'Every second night (2nd, 4th, 6th...), the Shaman wakes up last and can inspect one player.\n'
      'Unlike the Guard, the Shaman sees the player\'s true role, seeing through all disguises (Vampire, Drunk, etc.).\n'
      'The Shaman cannot inspect himself.\n'
      'WRAITH: A restless spirit bound to the village. The Wraith cannot be killed by any means — not by werewolves, plague, hanging, or execution. It lingers eternally, watching over the living.\n'
      'DIRE WOLF: A terrifying alpha predator aligned with the Werewolves.\n'
      'Wakes up with the pack and participates in the kill.\n'
      'After the wolves sleep, the Dire Wolf wakes alone every other night (1st, 3rd, 5th...) to silence one player.\n'
      'The silenced player cannot use their active ability the following night.\n'
      'Silence only affects roles that wake up at night: Doctor, Guard, Plague Doctor, and Shaman.\n'
      'Passive abilities (Knight armor, Wraith immortality, Jester, Executioner) are not affected.\n'
      'Cannot silence wolves, himself, or the same player as last time.\n'
      'Appears as a Werewolf when inspected by the Guard.\n\n'
      '7. Scoring:\n'
      'Points are awarded to members of the winning alliance at the end of the game.\n'
      'Different roles grant different amounts of points depending on their difficulty.\n'
      'Full point distributions can be found in the Roles section of the game.\n'
      'Special roles do not belong to an alliance and instead have their own winning conditions.\n'
      'Enjoy the mystery and deception. Good luck!\n\n',
  'werewolf_game': 'WEREWOLVES GAME',
  'roles_title': 'ROLES',
  'all_label': 'ALL',
  'pts': 'pts',
  'alliance_label': 'ALLIANCE',
  'win_pts_label': 'WIN: {points} PTS',
  'tap_to_flip_card': 'TAP CARD TO FLIP',
  'villager_name': 'Villager',
  'villager_desc': 'A simple townsperson trying to survive the night.',
  'werewolf_name': 'Werewolf',
  'werewolf_desc':
      'A fierce predator hungry for villagers. Each night, they can kill one player. Wins if they outnumber the village.',
  'doctor_name': 'Doctor',
  'doctor_desc':
      'A dedicated healer. Each night, she can save one person from being attacked that night.',
  'guard_name': 'Guard',
  'guard_desc': 'A vigilant protector. Each night, he can inspect one player.',
  'plague_doctor_name': 'Plague Doctor',
  'plague_doctor_desc':
      'A mysterious healer. Each night, he can save one player but also has a small chance to kill him.',
  'twins_name': 'Twins',
  'twins_desc':
      'Two souls bound together. If one is hanged by the village, the other becomes an Avenging Twin. If one is killed by a werewolf, the other remains a villager.',
  'avenging_twin_name': 'Avenging Twin',
  'avenging_twin_desc':
      'A twin fueled by vengeance. When their sibling is hanged by the village, they embrace the darkness and join the werewolves.',
  'vampire_name': 'Vampire',
  'vampire_desc':
      'A dark creature of the night. Awakens and kills with the werewolves each night, but remains undetected by the Guard.',
  'jester_name': 'Jester',
  'jester_desc':
      'A silly trickster. Wants to be hanged by the village to claim victory.',
  'drunk_name': 'Drunk',
  'drunk_desc':
      'A confused drinker. Due to intoxication, he appears as a Werewolf to the Guard, but is actually a loyal Villager.',
  'knight_name': 'Knight',
  'knight_desc':
      'A brave warrior. He has armor that protects him from the first lethal attack. He only dies if attacked a second time.',
  'knight_armor_msg': "The Knight's armor protected him! (-1 Life)",
  'knight_overwhelmed_msg': "The Knight was overwhelmed by multiple attacks!",
  'puppet_master_name': 'Puppet Master',
  'puppet_master_desc':
      'A mysterious observer. Transforms into the role of the first person who gets hanged by the village.',
  'puppet_master_transforming': 'THE PUPPET MASTER IS EVOLVING...',
  'puppet_master_new_role': 'The new {role} has joined the village!',
  'puppet_master_gambler_bet_info':
      'The original Gambler bet that the {alliance} alliance would win. You have inherited this bet!',
  'puppet_master_ritual': 'ANCIENT RITUAL IN PROGRESS',
  'puppet_master_unleash': 'UNLEASH PUPPETS',
  'puppet_master_evolving': '--- EVOLVING ---',
  'villagers_alliance_name': 'Villagers',
  'villagers_alliance_desc':
      'The peaceful inhabitants of the village. Their goal is to find and eliminate all werewolves.',
  'werewolves_alliance_name': 'Werewolves',
  'werewolves_alliance_desc':
      'The predators of the night. Their goal is to outnumber the villagers to take over the town.',
  'specials_alliance_name': 'Specials',
  'specials_alliance_desc':
      'Independent roles with unique win conditions and special abilities.',
  'day_timer': 'DAY TIMER',
  'day_timer_info_title': 'DAY TIMER INFO',
  'day_timer_info_description':
      'The day timer does not force the day to end. It only serves as an indicator to the narrator that they can conclude the day time and force the players to make a decision.',
  'day_timer_options_title': 'TIMER OPTIONS:',
  'day_timer_option_5min': '5 MIN - Fixed 5 minute timer',
  'day_timer_option_10min': '10 MIN - Fixed 10 minute timer',
  'day_timer_option_30s': '30s/P - 30 seconds per player',
  'day_timer_option_infinity': '∞ - No timer (infinite)',
  'timer_5_min': '5 MIN',
  'timer_10_min': '10 MIN',
  'timer_30s_p': '30s/P',
  'timer_infinity': '∞',
  'prepare_game_title': 'PREPARE GAME',
  'players_count_label': 'PLAYERS: {count}',
  'selected_count_label': 'SELECTED: {count}',
  'need_more_roles': 'NEED {count} MORE ROLES',
  'remove_roles': 'REMOVE {count} ROLES',
  'need_predator': 'NEED AT LEAST ONE WEREWOLF OR VAMPIRE',
  'too_many_predators': 'TOO MANY WEREWOLVES / VAMPIRES',
  'proceed_button': 'PROCEED',
  'tap_to_reveal': 'TAP TO REVEAL',
  'role_details_title': 'ROLE DETAILS',
  'close_button': 'CLOSE',
  'bound_soul_label': 'BOUND SOUL:',
  'role_discovery_title': 'ROLE DISCOVERY',
  'role_discovery_instruction':
      'PASS THE PHONE TO THE PLAYERS TO REVEAL THEIR ROLES',
  'commence_night_button': 'COMMENCE NIGHT',
  'step_werewolves_title': 'WEREWOLVES & VAMPIRE',
  'step_doctor_title': 'THE DOCTOR',
  'step_guard_title': 'THE GUARD',
  'step_plague_doctor_title': 'PLAGUE DOCTOR',
  'step_werewolves_instruction': 'SELECT A TARGET to ELIMINATE',
  'step_doctor_instruction': 'SELECT A TARGET to HEAL',
  'step_guard_instruction': 'SELECT A TARGET to INSPECT',
  'step_plague_doctor_instruction': 'SELECT A TARGET (RISKY HEAL)',
  'end_night_button': 'END NIGHT',
  'next_step_button': 'NEXT STEP',
  'dawn_breaks_title': 'DAWN BREAKS',
  'peaceful_night_msg': 'It was a peaceful night.\nNo one died.',
  'tragedy_struck_msg': 'Tragedy has struck!',
  'player_is_dead_label': '{name} is dead',
  'start_day_button': 'START DAY',
  'the_pack_alliance_title': 'THE WEREWOLVES',
  'the_village_alliance_title': 'THE VILLAGE',
  'specials_alliance_title': 'SPECIALS',
  'doctor_saved_msg': 'The Doctor saved {name}!',
  'plague_doctor_saved_msg':
      'The Plague Doctor treated {name}... and they survived!',
  'plague_doctor_self_saved_msg':
      'The Plague Doctor treated himself... and he survived!',
  'plague_doctor_failed_msg':
      'The Plague Doctor tried to help {name}... but failed.',
  'plague_doctor_killed_msg':
      "The Plague Doctor's 'treatment' was fatal to {name}.",
  'plague_doctor_self_killed_msg':
      "The Plague Doctor's 'treatment' on himself was fatal!",
  'plague_doctor_treated_msg': 'The Plague Doctor treated {name}.',
  'plague_doctor_self_treated_msg': 'The Plague Doctor treated himself.',
  'doctor_saved_from_plague_msg':
      "The Doctor saved {name} from the Plague Doctor's fatal treatment!",
  'doctor_saved_from_both_msg':
      "The Doctor saved {name} from both the werewolves and the Plague Doctor's fatal treatment!",
  'double_heal_msg':
      '{name} was treated by both the Doctor and the Plague Doctor!',
  'double_save_from_werewolves_msg':
      'The werewolves attacked {name}, but both the Doctor and the Plague Doctor successfully saved them!',
  'win_title_village': 'THE VILLAGE WINS!',
  'win_title_werewolves': 'THE WEREWOLVES WIN!',
  'win_title_specials': 'THE SPECIALS WIN!',
  'win_title_jester': 'THE JESTER WINS!',
  'game_over_title': 'GAME OVER',
  'points_distributed_label': 'POINTS DISTRIBUTED',
  'no_points_awarded_msg': 'No points awarded.',
  'day_phase_title': 'DAY PHASE {number}',
  'night_phase_title': 'NIGHT PHASE {number}',
  'discuss_and_vote_instruction': 'DISCUSS & VOTE',
  'hang_button': 'HANG',
  'skip_button': 'SKIP',
  'select_button': 'SELECT',
  'votes_needed_label': 'VOTES NEEDED FOR HANGING:',
  'royal_guard_check': 'ROYAL GUARD // CHECK',
  'approaching': 'APPROACHING...',
  'searching': 'SEARCHING...',
  'looking_for_mark': 'LOOKING FOR THE MARK...',
  'monster_found': 'MONSTER\nFOUND',
  'citizen_cleared': 'PERSON\nCLEARED',
  'target_is_werewolf': 'Target is a WEREWOLF',
  'target_is_villager': 'Target is a VILLAGER',
  'processing': 'PROCESSING...',
  'investigate_button': 'INVESTIGATE',
  'executioner_name': 'Executioner',
  'executioner_desc':
      'A vengeful villager. If hanged by the village, he can take one player with him to the grave.',
  'executioner_retaliation_title': 'EXECUTIONER RETALIATION',
  'executioner_retaliation_desc':
      'The Executioner has been hanged! He takes someone with him. Select a victim.',
  'confirm_button': 'CONFIRM',
  'execute_button': 'EXECUTE',
  'infected_name': 'Infected',
  'infected_desc':
      'A villager carrying a hidden sickness. If the Doctor heals them, the Doctor gets infected and dies. If the werewolves target them at night while they have a vampire in their team, the vampire gets infected and dies.',
  'infected_doctor_msg':
      'An infection spread from {name} while the Doctor was treating them! The Doctor has DIED!',
  'infected_vampire_msg':
      'The infection spread to the Vampire during the attack on {name}! The Vampire has DIED!',
  'gambler_name': 'Gambler',
  'gambler_desc':
      'A cunning risk-taker who bets on fate. On the first night, they secretly choose which alliance they believe will win. If correct, they share in the victory points. Behaves as a normal villager otherwise.',
  'step_gambler_title': 'THE GAMBLER',
  'step_gambler_instruction': 'PLACE YOUR BET ON THE WINNING ALLIANCE',
  'gambler_bet_title': 'PLACE YOUR BET',
  'gambler_bet_subtitle': 'Choose who you think will win...',
  'gambler_bet_village': 'THE VILLAGE',
  'gambler_bet_werewolves': 'THE WEREWOLVES',
  'gambler_bet_specials': 'THE SPECIALS',
  'gambler_village_reward': '+1 POINT',
  'gambler_werewolves_reward': '+2 POINTS',
  'gambler_specials_reward': '+3 POINTS',
  'gambler_confirm_bet': 'CONFIRM BET',
  'gambler_roll_dice': 'ROLL THE DICE',
  'gambler_fate_sealed': 'YOUR FATE IS SEALED',
  'gambler_won_bet': 'THE GAMBLER WON THE BET!',
  'shaman_name': 'Shaman',
  'shaman_desc':
      'A mystical seer who communes with the spirits. Every second night, the Shaman can inspect one player and learn their true role. Unlike the Guard, the Shaman sees through all disguises.',
'step_shaman_title': 'THE SHAMAN',
'step_shaman_instruction': 'SELECT A TARGET TO DIVINE',
'shaman_vision_title': 'THE VISION',
'shaman_channeling': 'SEEKING THE TRUTH...',
'shaman_spirits_reveal': 'THE TRUTH IS REVEALED...',
  'wraith_name': 'Wraith',
  'wraith_desc':
      'A restless spirit bound to the village. The Wraith cannot be killed by any means — not by werewolves, plague, hanging, or execution. It lingers eternally, watching over the living.',
  'wraith_immune_werewolf_msg': 'The Wraith was targeted by werewolves, but their claws passed through its spectral form!',
  'wraith_immune_plague_msg': 'The Plague Doctor\'s concoction had no effect on the Wraith\'s ethereal body!',
  'wraith_immune_hanging_msg': 'THE WRAITH CANNOT BE HANGED — THE ROPE PASSES THROUGH!',
  'wraith_immune_executioner_msg': 'The Executioner\'s blade phases through the Wraith!',
  'dire_wolf_name': 'Dire Wolf',
  'dire_wolf_desc':
      'A terrifying alpha predator. Hunts with the pack, then wakes alone every other night to silence one player, preventing them from using their ability the following night.',
  'step_dire_wolf_title': 'THE DIRE WOLF',
  'step_dire_wolf_instruction': 'SELECT A TARGET TO SILENCE',
  'silenced_indicator': 'SILENCED',
  'analytics_title': 'PLAYER STATS',
  'analytics_total_games': 'TOTAL GAMES',
  'analytics_wins': 'WINS',
  'analytics_losses': 'LOSSES',
  'analytics_win_rate': 'WIN RATE',
  'analytics_alliance_breakdown': 'WINS BY ALLIANCE',
  'analytics_role_history': 'ROLE HISTORY',
  'analytics_played': 'PLAYED',
  'analytics_won': 'WON',
  'analytics_no_games': 'No games recorded yet.',
  'analytics_village_wins': 'VILLAGE',
  'analytics_werewolf_wins': 'WEREWOLVES',
  'analytics_special_wins': 'SPECIALS',
};
