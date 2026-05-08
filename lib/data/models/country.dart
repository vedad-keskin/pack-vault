class Country {
  final int id;
  final String name;
  final String flagEmoji;

  const Country({
    required this.id,
    required this.name,
    required this.flagEmoji,
  });

  static const List<Country> all = [
    Country(id: 1, name: 'Mexico', flagEmoji: '🇲🇽'),
    Country(id: 2, name: 'Switzerland', flagEmoji: '🇨🇭'),
    Country(id: 3, name: 'Brazil', flagEmoji: '🇧🇷'),
    Country(id: 4, name: 'Morocco', flagEmoji: '🇲🇦'),
    Country(id: 5, name: 'Scotland', flagEmoji: '🏴󠁧󠁢󠁳󠁣󠁴󠁿'),
    Country(id: 6, name: 'USA', flagEmoji: '🇺🇸'),
    Country(id: 7, name: 'Australia', flagEmoji: '🇦🇺'),
    Country(id: 8, name: 'Germany', flagEmoji: '🇩🇪'),
    Country(id: 9, name: 'Netherlands', flagEmoji: '🇳🇱'),
    Country(id: 10, name: 'Japan', flagEmoji: '🇯🇵'),
    Country(id: 11, name: 'Tunis', flagEmoji: '🇹🇳'),
    Country(id: 12, name: 'Belgium', flagEmoji: '🇧🇪'),
    Country(id: 13, name: 'Senegal', flagEmoji: '🇸🇳'),
    Country(id: 14, name: 'Spain', flagEmoji: '🇪🇸'),
    Country(id: 15, name: 'Uruguay', flagEmoji: '🇺🇾'),
    Country(id: 16, name: 'France', flagEmoji: '🇫🇷'),
    Country(id: 17, name: 'Norway', flagEmoji: '🇳🇴'),
    Country(id: 18, name: 'Argentina', flagEmoji: '🇦🇷'),
    Country(id: 19, name: 'Algerie', flagEmoji: '🇩🇿'),
    Country(id: 20, name: 'Austria', flagEmoji: '🇦🇹'),
    Country(id: 21, name: 'Portugal', flagEmoji: '🇵🇹'),
    Country(id: 22, name: 'Italy', flagEmoji: '🇮🇹'),
    Country(id: 23, name: 'Croatia', flagEmoji: '🇭🇷'),
    Country(id: 24, name: 'England', flagEmoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
    Country(id: 25, name: 'Bosnia and Herzegovina', flagEmoji: '🇧🇦'),
    Country(id: 26, name: 'Legends', flagEmoji: '⭐'),
  ];

  static Country getById(int id) {
    return all.firstWhere((c) => c.id == id);
  }
}
