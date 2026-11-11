import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../../core/services/app_services.dart';

class CmsPageScreen extends StatefulWidget {
  final String slug;

  const CmsPageScreen({
    super.key,
    required this.slug,
  });

  @override
  State<CmsPageScreen> createState() => _CmsPageScreenState();
}

class _CmsPageScreenState extends State<CmsPageScreen> {
  late Future<Map<String, dynamic>> _pageFuture;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  void _loadPage() {
    _pageFuture = AppServices.pages.fetchPage(widget.slug);
  }

  void _retry() {
    setState(() {
      _loadPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _pageFuture,
          builder: (context, snapshot) {
            final title = snapshot.data?['title']?.toString();

            return Text(
              title?.isNotEmpty == true ? title! : 'Loading...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load page.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Page not found.'),
            );
          }

          final page = snapshot.data!;
          final content = page['content']?.toString() ?? '';
          final excerpt = page['excerpt']?.toString() ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (excerpt.isNotEmpty) ...[
                  Text(
                    excerpt,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (content.isNotEmpty)
                  HtmlWidget(
                    content,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                    ),
                  )
                else
                  const Text('No content available.'),
              ],
            ),
          );
        },
      ),
    );
  }
}
