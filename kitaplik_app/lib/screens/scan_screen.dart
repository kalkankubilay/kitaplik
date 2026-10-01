import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/google_books_service.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import 'book_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  /// false = Okuduklarıma Ekle, true = Okumak İstediklerime Ekle
  bool _isWishlist = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String isbn) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await _controller.stop();

    // Duplicate check
    if (HiveService.bookExists(isbn)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu kitap zaten kitaplığınızda mevcut!'),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );

    final book = await GoogleBooksService.fetchBookByIsbn(isbn);
    if (!mounted) return;
    Navigator.of(context).pop(); // close loading

    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kitap bulunamadı. ISBN\'i kontrol edin.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      setState(() => _isProcessing = false);
      _controller.start();
      return;
    }

    // Kullanıcının seçtiği toggle'a göre isWishlist set et
    book.isWishlist = _isWishlist;
    await HiveService.addBook(book);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book, isNew: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Barkod Tara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  _handleBarcode(raw);
                  break;
                }
              }
            },
          ),

          // Tarama çerçevesi
          Center(
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Alt bilgi yazısı
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: const Text(
              'Kitabın barkodunu çerçeve içine hizalayın',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),

          // Toggle — listeye ekleme seçimi
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: _buildToggle(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _toggleOption(
            label: 'Okuduklarıma Ekle',
            icon: Icons.menu_book_rounded,
            active: !_isWishlist,
            onTap: () => setState(() => _isWishlist = false),
          ),
          _toggleOption(
            label: 'Okumak İstediklerime',
            icon: Icons.bookmark_add_rounded,
            active: _isWishlist,
            onTap: () => setState(() => _isWishlist = true),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppTheme.bg : Colors.white54,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? AppTheme.bg : Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
