import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  final String isbn;

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  String coverUrl;

  @HiveField(4)
  double rating;

  @HiveField(5)
  String note;

  @HiveField(6)
  DateTime addedAt;

  @HiveField(7)
  bool isWishlist;

  @HiveField(8)
  int pageCount;

  @HiveField(9)
  String edition;

  Book({
    required this.isbn,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.rating = 0,
    this.note = '',
    required this.addedAt,
    this.isWishlist = false,
    this.pageCount = 0,
    this.edition = '',
  });
}
