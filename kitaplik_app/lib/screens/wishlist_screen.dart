import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/book.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import 'book_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Book> _books = [];
  final TextEditingController _searchController = TextEditingController();
  List<Book> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final books = HiveService.getWishlistBooks();
    setState(() {
      _books = books;
      _filtered = books;
    });
  }

  void _filter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_books)
          : _books.where((b) {
              return b.title.toLowerCase().contains(q) ||
                  b.author.toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _goToDetail(Book book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
    if (result == true) _load();
  }

  Future<void> _showManualAddDialog() async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Okuma Listesine Ekle',
                    style: TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _dialogField(titleCtrl, 'Kitap Adı *', Icons.book_rounded),
              const SizedBox(height: 12),
              _dialogField(authorCtrl, 'Yazar *', Icons.person_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final author = authorCtrl.text.trim();
                    if (title.isEmpty || author.isEmpty) return;
                    final book = Book(
                      isbn: 'wishlist_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      author: author,
                      coverUrl: '',
                      addedAt: DateTime.now(),
                      isWishlist: true,
                    );
                    await HiveService.addBook(book);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textHigh, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textGhost, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textGhost, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildSearchBar(),
              ),
            ),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Okuma Listem',
                          style: TextStyle(
                            color: AppTheme.textHigh,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.01,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '${_filtered.length}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _showManualAddDialog,
                      icon: const Icon(Icons.add_rounded, color: AppTheme.textMuted, size: 24),
                    ),
                  ],
                ),
              ),
            ),

            // List
            if (_filtered.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 350),
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(
                            child: _buildTile(_filtered[index]),
                          ),
                        ),
                      );
                    },
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.bookmark_rounded, color: AppTheme.primaryViolet, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Okumak İstediklerim',
            style: TextStyle(
              color: AppTheme.textHigh,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.01,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textHigh, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Kitap veya yazar ara...',
          hintStyle: TextStyle(color: AppTheme.textGhost, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppTheme.textGhost, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildTile(Book book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => _goToDetail(book),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.coverUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: book.coverUrl,
                  width: 48,
                  height: 68,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _placeholder(),
                  errorWidget: (_, _, _) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textHigh,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Okuma Listesi',
                style: TextStyle(
                  color: AppTheme.primaryViolet,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textGhost),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 68,
      color: AppTheme.surfaceHigh,
      child: const Icon(Icons.auto_stories_rounded, color: AppTheme.textGhost, size: 22),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.bookmark_add_rounded, size: 32, color: AppTheme.textGhost),
            ),
            const SizedBox(height: 18),
            const Text(
              'Okuma Listesi Boş',
              style: TextStyle(
                color: AppTheme.textHigh,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
