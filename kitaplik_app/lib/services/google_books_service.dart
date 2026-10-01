import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  static Future<Book?> fetchBookByIsbn(String isbn) async {
    try {
      final uri = Uri.parse('$_baseUrl?q=isbn:$isbn');
      final response = await http.get(uri);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['totalItems'] == 0) return null;

      final volumeInfo = data['items'][0]['volumeInfo'] as Map<String, dynamic>;

      final title = volumeInfo['title'] as String? ?? 'Bilinmeyen Kitap';
      final authors = volumeInfo['authors'] as List<dynamic>?;
      final author = authors != null ? authors.join(', ') : 'Bilinmeyen Yazar';

      String coverUrl = '';
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      if (imageLinks != null) {
        coverUrl = (imageLinks['thumbnail'] as String? ?? '')
            .replaceFirst('http://', 'https://');
      }

      return Book(
        isbn: isbn,
        title: title,
        author: author,
        coverUrl: coverUrl,
        addedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }
}
