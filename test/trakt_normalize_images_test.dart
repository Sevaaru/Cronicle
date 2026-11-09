import 'package:cronicle/features/trakt/data/trakt_normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('show poster falls back to fanart and upgrades http', () {
    final norm = normalizeTraktShow({
      'title': 'The Show',
      'ids': {'trakt': 12},
      'images': {
        'poster': <String>[],
        'fanart': {
          'full': 'http://image.tmdb.org/t/p/original/abc.jpg',
        },
      },
    });
    final cover = norm['coverImage'] as Map<String, dynamic>;
    expect(cover['large'], 'https://image.tmdb.org/t/p/original/abc.jpg');
  });

  test('bare tmdb path becomes a poster url', () {
    final norm = normalizeTraktShow({
      'title': 'Other',
      'ids': {'trakt': 4},
      'images': {
        'poster': [
          {'file_path': '/xyz.jpg'},
        ],
      },
    });
    final cover = norm['coverImage'] as Map<String, dynamic>;
    expect(cover['large'], 'https://image.tmdb.org/t/p/w342/xyz.jpg');
  });
}
