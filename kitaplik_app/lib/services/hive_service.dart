import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';

class HiveService {
  static const String _boxName = 'books';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(BookAdapter());
    await Hive.openBox<Book>(_boxName);
  }

  static Box<Book> get box => Hive.box<Book>(_boxName);

  static List<Book> getAllBooks() {
    final books = box.values.toList();
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return books;
  }

  /// Okuduğum kitaplar (isWishlist == false)
  static List<Book> getReadBooks() {
    final books = box.values.where((b) => !b.isWishlist).toList();
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return books;
  }

  /// Okumak istediğim kitaplar (isWishlist == true)
  static List<Book> getWishlistBooks() {
    final books = box.values.where((b) => b.isWishlist).toList();
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return books;
  }

  static Future<void> addBook(Book book) async {
    await box.put(book.isbn, book);
  }

  static Future<void> updateBook(Book book) async {
    await book.save();
  }

  static Future<void> deleteBook(String isbn) async {
    await box.delete(isbn);
  }

  static bool bookExists(String isbn) {
    return box.containsKey(isbn);
  }
}

