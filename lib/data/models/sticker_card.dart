class StickerCard {
  final int id;
  final String fullName;
  final int page;
  final int countryId;

  const StickerCard({
    required this.id,
    this.fullName = '',
    required this.page,
    required this.countryId,
  });
}
