class UserModel {
  final String uid;
  final String username;
  final Map<int, bool> cards;

  const UserModel({
    required this.uid,
    required this.username,
    required this.cards,
  });

  int get collectedCount => cards.values.where((v) => v).length;
  int get totalCards => cards.length;
  double get progress => totalCards > 0 ? collectedCount / totalCards : 0;
}
