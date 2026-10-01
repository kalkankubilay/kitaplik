import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/book.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';
import 'scan_screen.dart';
import 'wishlist_screen.dart';

enum BookFilter { all, rated, favorites, recent }

/// Ana shell — 5 sekme: Ana Sayfa | ? | Barkod (aksiyon) | Okumak İstediklerim | Okuduklarım
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0=Dashboard, 1=Placeholder, 2=Scan(action-no tab), 3=Wishlist, 4=ReadBooks
  int _currentNavIndex = 0;

  final _readKey = GlobalKey<_ReadBooksTabState>();
  final _wishlistKey = GlobalKey<_WishlistShellState>();

  Future<void> _goToScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    _readKey.currentState?.reload();
    _wishlistKey.currentState?.reload();
  }

  /// Nav index → IndexedStack body index mapping (scan=2 is action only)
  int _bodyIndex(int nav) {
    switch (nav) {
      case 0: return 0; // Dashboard
      case 1: return 1; // Placeholder
      case 3: return 2; // Wishlist
      case 4: return 3; // ReadBooks
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _bodyIndex(_currentNavIndex),
        children: [
          _DashboardTab(onScan: _goToScan),
          const _PlaceholderTab(),
          _WishlistShell(key: _wishlistKey, onScan: _goToScan),
          _ReadBooksTab(key: _readKey, onScan: _goToScan),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface2.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, 'Ana Sayfa'),
              _navItem(1, Icons.help_outline_rounded, '?'),
              // Merkez barkod aksiyonu
              Expanded(
                child: GestureDetector(
                  onTap: _goToScan,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, color: AppTheme.bg, size: 22),
                        SizedBox(height: 3),
                        Text(
                          'Tara',
                          style: TextStyle(
                            color: AppTheme.bg,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _navItem(3, Icons.bookmark_rounded, 'Okumak\nİstediklerim'),
              _navItem(4, Icons.menu_book_rounded, 'Okuduklarım'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentNavIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentNavIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? AppTheme.primary : AppTheme.textGhost,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? AppTheme.primary : AppTheme.textGhost,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — Okuduğum Kitaplar
// ─────────────────────────────────────────────────────────────────────────────
class _ReadBooksTab extends StatefulWidget {
  final VoidCallback onScan;
  const _ReadBooksTab({super.key, required this.onScan});

  @override
  State<_ReadBooksTab> createState() => _ReadBooksTabState();
}

class _ReadBooksTabState extends State<_ReadBooksTab> {
  List<Book> _books = [];
  List<Book> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isGrid = true;
  BookFilter _currentFilter = BookFilter.all;

  @override
  void initState() {
    super.initState();
    reload();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void reload() {
    final books = HiveService.getReadBooks();
    setState(() => _books = books);
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    List<Book> result = List.from(_books);

    switch (_currentFilter) {
      case BookFilter.rated:
        result = result.where((b) => b.rating > 0).toList();
        break;
      case BookFilter.favorites:
        result = result.where((b) => b.rating >= 4.0).toList();
        break;
      case BookFilter.recent:
        result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case BookFilter.all:
        break;
    }

    if (query.isNotEmpty) {
      result = result.where((b) {
        return b.title.toLowerCase().contains(query) ||
            b.author.toLowerCase().contains(query) ||
            b.isbn.toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _filtered = result);
  }

  Future<void> _goToDetail(Book book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
    if (result == true) reload();
  }

  int get _ratedCount => _books.where((b) => b.rating > 0).length;

  Future<void> _showManualAddDialog() async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pageCtrl = TextEditingController();
    final editionCtrl = TextEditingController();

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
                    'Kitap Ekle',
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
              const SizedBox(height: 12),
              _dialogField(pageCtrl, 'Sayfa Sayısı', Icons.format_list_numbered_rounded,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _dialogField(editionCtrl, 'Baskı (ör: 3. Baskı)', Icons.layers_rounded),
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
                      isbn: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      author: author,
                      coverUrl: '',
                      addedAt: DateTime.now(),
                      isWishlist: false,
                      pageCount: int.tryParse(pageCtrl.text.trim()) ?? 0,
                      edition: editionCtrl.text.trim(),
                    );
                    await HiveService.addBook(book);
                    if (ctx.mounted) Navigator.pop(ctx);
                    reload();
                  },
                  child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );

    titleCtrl.dispose();
    authorCtrl.dispose();
    pageCtrl.dispose();
    editionCtrl.dispose();
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
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
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildSearchBar(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
              child: _buildFilterPills(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Kütüphanem',
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showManualAddDialog,
                        icon: const Icon(Icons.add_rounded, color: AppTheme.textMuted, size: 24),
                        tooltip: 'Manuel Kitap Ekle',
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isGrid = !_isGrid),
                        icon: Icon(
                          _isGrid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                          color: AppTheme.textMuted,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_filtered.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else if (_isGrid)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 350),
                      columnCount: 2,
                      child: ScaleAnimation(
                        scale: 0.95,
                        child: FadeInAnimation(
                          child: BookCard(
                            book: _filtered[index],
                            onTap: () => _goToDetail(_filtered[index]),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            )
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
                          child: _buildListTile(_filtered[index]),
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
              color: AppTheme.emerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppTheme.emerald, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Okuduğum Kitaplar',
                style: TextStyle(
                  color: AppTheme.textHigh,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.01,
                ),
              ),
              Text(
                '${_books.length} kitap · $_ratedCount puanlı',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
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
        decoration: InputDecoration(
          hintText: 'Kitap veya yazar ara...',
          hintStyle: const TextStyle(color: AppTheme.textGhost, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textGhost, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textGhost, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _filterPill(filter: BookFilter.all, label: 'Tümü (${_books.length})'),
          const SizedBox(width: 8),
          _filterPill(filter: BookFilter.rated, label: 'Puanlananlar ($_ratedCount)'),
          const SizedBox(width: 8),
          _filterPill(filter: BookFilter.favorites, label: 'Favoriler ★ 4+'),
          const SizedBox(width: 8),
          _filterPill(filter: BookFilter.recent, label: 'Son Eklenenler'),
        ],
      ),
    );
  }

  Widget _filterPill({required BookFilter filter, required String label}) {
    final active = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _currentFilter = filter);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.bg : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(Book book) {
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
                  placeholder: (_, _) => _miniPlaceholder(),
                  errorWidget: (_, _, _) => _miniPlaceholder(),
                )
              : _miniPlaceholder(),
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
            Row(
              children: [
                if (book.rating > 0) ...[
                  const Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    book.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Okundu',
                    style: TextStyle(
                      color: AppTheme.emeraldLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textGhost),
      ),
    );
  }

  Widget _miniPlaceholder() {
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
              child: const Icon(Icons.menu_book_rounded, size: 32, color: AppTheme.textGhost),
            ),
            const SizedBox(height: 18),
            const Text(
              'Henüz Kitap Eklenmedi',
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

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Ana Sayfa Dashboard
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  final VoidCallback onScan;
  const _DashboardTab({required this.onScan});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _books = HiveService.getAllBooks());
  }

  int get _readCount => _books.where((b) => !b.isWishlist).length;
  int get _wishCount => _books.where((b) => b.isWishlist).length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildMetricsGrid(),
            ),
          ),
          if (_books.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildAlertCard(),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
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
      child: const Text(
        'Merhaba, Kubilay 👋',
        style: TextStyle(
          color: AppTheme.textHigh,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02,
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        _metricTile(
          icon: Icons.menu_book_rounded,
          iconColor: AppTheme.emerald,
          value: '$_readCount Kitap',
          label: 'Okuduklarım',
        ),
        const SizedBox(height: 12),
        _metricTile(
          icon: Icons.bookmark_rounded,
          iconColor: AppTheme.primaryViolet,
          value: '$_wishCount Kitap',
          label: 'Okumak İstediklerim',
        ),
      ],
    );
  }

  Widget _metricTile({
    required IconData icon,
    Color? iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: iconColor ?? AppTheme.textHigh, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textHigh,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.02,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildAlertCard() {
    final latestBook = _books.firstWhere((b) => !b.isWishlist, orElse: () => _books.first);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.schedule_rounded, color: AppTheme.gold, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OKUMA HATIRLATMASI',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.35),
                    children: [
                      TextSpan(
                        text: '\'${latestBook.title}\' ',
                        style: const TextStyle(color: AppTheme.textHigh, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: 'kitabınız sizi bekliyor. Bugün 20 dakikalık okuma oturumu öneriliyor.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Wishlist Shell (delegating to WishlistScreen content)
// ─────────────────────────────────────────────────────────────────────────────
class _WishlistShell extends StatefulWidget {
  final VoidCallback onScan;
  const _WishlistShell({super.key, required this.onScan});

  @override
  State<_WishlistShell> createState() => _WishlistShellState();
}

class _WishlistShellState extends State<_WishlistShell> {
  void reload() => setState(() {});

  @override
  Widget build(BuildContext context) => const WishlistScreen();
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder Tab — 2. sıradaki soru işareti butonu için boş ekran
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: 48, color: AppTheme.textGhost),
            SizedBox(height: 12),
            Text(
              'Yakında...',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
