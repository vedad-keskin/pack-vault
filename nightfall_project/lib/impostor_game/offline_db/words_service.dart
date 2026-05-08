import 'data/words_lokacije.dart';
import 'data/words_hrana.dart';
import 'data/words_crtani.dart';
import 'data/words_poznati.dart';
import 'data/words_predmeti.dart';
import 'data/words_anime.dart';
import 'data/words_islam.dart';
import 'data/words_znamenitosti.dart';
import 'data/words_borci.dart';
import 'data/words_brendovi.dart';
import 'data/words_igre.dart';
import 'data/words_sportovi.dart';
import 'data/words_zivotinje.dart';
import 'data/words_filmovi.dart';

class Word {
  final int id;
  final String name;
  final int categoryId;
  final String hint;

  Word({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.hint,
  });
}

class WordsService {
  // Category IDs:
  // 1: Lokacije
  // 2: Hrana
  // 3: Crtani

  static final List<Word> _words = [
    ...lokacijeWords,
    ...hranaWords,
    ...crtaniWords,
    ...poznatiWords,
    ...predmetiWords,
    ...animeWords,
    ...islamWords,
    ...znamenitostiWords,
    ...borciWords,
    ...brendoviWords,
    ...igreWords,
    ...sportoviWords,
    ...zivotinjeWords,
    ...filmoviWords,
  ];

  List<Word> getAllWords() {
    return _words;
  }

  List<Word> getWordsForCategory(int categoryId) {
    return _words.where((w) => w.categoryId == categoryId).toList();
  }

  int getWordCountForCategory(int categoryId) {
    return _words.where((w) => w.categoryId == categoryId).length;
  }
}
