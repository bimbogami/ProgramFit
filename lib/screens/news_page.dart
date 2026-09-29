import 'package:flutter/material.dart';

import '../services/supabase_news_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _isLoading = true;
  List<NewsPost> _updates = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUniversityUpdates();
  }

  Future<void> _loadUniversityUpdates() async {
    try {
      final service = SupabaseNewsService();
      final rows = await service.fetchUniversityUpdates();
      if (!mounted) return;

      setState(() {
        _updates = rows;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _updates = const [];
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  } 

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('University Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('Latest university updates', style: TextStyle(fontSize: 12, color: Color(0xFF6B6254))),
                ],
              ),
            ),
            IconButton(
              onPressed: _isLoading ? null : _loadUniversityUpdates,
              tooltip: 'Refresh updates',
              icon: const Icon(Icons.refresh_rounded, size: 21),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFFDED),
                side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          _buildErrorState()
        else if (_updates.isEmpty)
          _buildEmptyState()
        else
          ..._updates.map((post) => _buildUpdateCard(context, post)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _frameDecoration(),
      child: const Text(
        'Bummer, Stay tuned for campus announcements and academic schedules',
        style: TextStyle(color: Color(0xFF6B6254)),
      ),
    );
  }

  BoxDecoration _frameDecoration({Color color = const Color(0xFFFFFDED)}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      boxShadow: const [
        BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(3, 4), blurRadius: 0),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _frameDecoration(color: const Color(0xFFFFF3F1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('University updates could not be loaded.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_errorMessage!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6254))),
          TextButton.icon(onPressed: _loadUniversityUpdates, icon: const Icon(Icons.refresh, size: 18), label: const Text('Try again')),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, NewsPost post) {
    return GestureDetector(
      onTap: () => _showArticle(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: _frameDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.imgHeader.trim().isNotEmpty)
              Image.network(post.imgHeader, height: 164, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 164, child: Center(child: Icon(Icons.image_not_supported)))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatElapsed(post.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2856B8))),
                  const SizedBox(height: 6),
                  Text(post.head, style: const TextStyle(fontSize: 19, height: 1.15, fontWeight: FontWeight.w800, color: Color(0xFF18181B))),
                  const SizedBox(height: 6),
                  Text(post.desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF5F5A52))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArticle(NewsPost post) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(4, 2), blurRadius: 0),
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 86, 20, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (post.imgHeader.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 440),
                            child: Image.network(
                              post.imgHeader,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 220,
                                child: Center(child: Icon(Icons.image_not_supported)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _formatElapsed(post.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF2856B8),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        post.head,
                        style: const TextStyle(
                          color: Color(0xFF18181B),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        post.desc,
                        style: const TextStyle(
                          color: Color(0xFF5F5A52),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 76,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFDED),
                            Color(0xFFFFFDED),
                            Color(0x00FFFDED),
                          ],
                          stops: [0.0, 0.62, 1.0],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 92,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFFFFDED),
                            Color(0xFFFFFDED),
                            Color(0x00FFFDED),
                          ],
                          stops: [0.0, 0.68, 1.0],
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFDED),
                      side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.close, size: 26, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatElapsed(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    final minutes = diff.inMinutes;
    if (minutes < 5) {
      return '5 mins ago';
    }

    if (minutes < 60) {
      return '$minutes mins ago';
    }

    final hours = diff.inHours;
    if (hours < 24) {
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }

    final days = diff.inDays;
    return days == 1 ? '1 day ago' : '$days days ago';
  }
}

class LoadingOwl extends StatefulWidget {
  const LoadingOwl({super.key});

  @override
  State<LoadingOwl> createState() => _LoadingOwlState();
}

class _LoadingOwlState extends State<LoadingOwl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const String _loadingText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/loading_owl.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_loadingText.length, (letterIndex) {
                  final start = letterIndex / _loadingText.length;
                  final end = (start + 0.35).clamp(0.0, 1.0);
                  final progress = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, end, curve: Curves.easeOutBack),
                  ).value;

                  return Transform.scale(
                    scale: 0.75 + (progress * 0.25),
                    child: Opacity(
                      opacity: 0.45 + (progress * 0.55),
                      child: Text(
                        _loadingText[letterIndex],
                        style: const TextStyle(
                          color: Color.fromARGB(255, 12, 34, 87),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
