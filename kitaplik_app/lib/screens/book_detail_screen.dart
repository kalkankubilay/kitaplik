import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final bool isNew;

  const BookDetailScreen({
    super.key,
    required this.book,
    this.isNew = false,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late double _rating;
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.book.rating;
    _noteController = TextEditingController(text: widget.book.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    widget.book.rating = _rating;
    widget.book.note = _noteController.text.trim();
    await HiveService.updateBook(widget.book);
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Kaydedildi', style: TextStyle(color: AppTheme.textHigh)),
          ],
        ),
        backgroundColor: AppTheme.surface2,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textGhost,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kitabı Sil',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textHigh,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.book.title}" kitaplığınızdan kalıcı olarak silinecek.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Sil',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await HiveService.deleteBook(widget.book.isbn);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero Cover App Bar ────────────────────────────
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppTheme.bg,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover image
                      if (widget.book.coverUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: widget.book.coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _coverFallback(),
                        )
                      else
                        _coverFallback(),
                      // Gradient fade
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                              AppTheme.bg,
                            ],
                            stops: const [0.2, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Book info overlay at bottom
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book.title,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.book.author,
                              style: TextStyle(
                                color: Colors.purple[200],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ISBN: ${widget.book.isbn}',
                              style: const TextStyle(
                                color: AppTheme.textGhost,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating section
                      _sectionLabel('Puanınız'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            RatingBar.builder(
                              initialRating: _rating,
                              minRating: 0,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemPadding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              glow: true,
                              glowColor: AppTheme.gold.withValues(alpha: 0.3),
                              itemBuilder: (_, _) => const Icon(
                                Icons.star_rounded,
                                color: AppTheme.gold,
                              ),
                              onRatingUpdate: (r) =>
                                  setState(() => _rating = r),
                            ),
                            if (_rating > 0) ...[
                              const SizedBox(height: 12),
                              Text(
                                _ratingLabel(_rating),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Note section
                      Row(
                        children: [
                          _sectionLabel('Notunuz'),
                          const Spacer(),
                          Text(
                            '${_noteController.text.length} / 500',
                            style: const TextStyle(
                              color: AppTheme.textGhost,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 7,
                          maxLength: 500,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: AppTheme.textHigh,
                            fontSize: 14,
                            height: 1.6,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Bu kitap hakkında düşüncelerinizi yazın...',
                            hintStyle: TextStyle(
                              color: AppTheme.textGhost,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Sticky Save Button ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.bg.withValues(alpha: 0.0),
                    AppTheme.bg,
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _isSaving ? null : AppTheme.primaryGradient,
                    color: _isSaving ? AppTheme.surface1 : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isSaving ? null : AppTheme.glowShadow,
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Kaydet',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: AppTheme.textHigh,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface2, AppTheme.surface1],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: AppTheme.primary,
          size: 80,
        ),
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 5) return '⭐ Olağanüstü bir başyapıt';
    if (r >= 4) return '✨ Harika bir kitap';
    if (r >= 3) return '👍 İyi ve okunmaya değer';
    if (r >= 2) return '😐 Ortalama';
    return '👎 Hayal kırıklığı';
  }
}
