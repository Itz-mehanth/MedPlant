import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'NewsDetailsPage.dart';
import 'package:url_launcher/url_launcher.dart';

class AyurvedaNewsWidget extends StatefulWidget {
  const AyurvedaNewsWidget({super.key});

  @override
  State<AyurvedaNewsWidget> createState() => _AyurvedaNewsWidgetState();
}

class _AyurvedaNewsWidgetState extends State<AyurvedaNewsWidget> {
  // Professional color scheme matching your app
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGray = Color(0xFF2C2C2C);

  List<NewsItem> newsItems = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNewsFromAPI();
  }

  Future<void> _fetchNewsFromAPI() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use the API key from your config
      const apiKey = NewsApiConfig.apiKey;
      const baseUrl = NewsApiConfig.baseUrl;

      // NewsAPI free plan earliest allowed date (update as needed)
      final earliestAllowed = DateTime(2025, 8, 7);
      final calculatedFrom = DateTime.now().subtract(const Duration(days: 7));
      final fromDate = calculatedFrom.isBefore(earliestAllowed)
          ? earliestAllowed.toIso8601String().split('T')[0]
          : calculatedFrom.toIso8601String().split('T')[0];

      // Search for Ayurveda related news
      final searchQuery =
          'ayurveda OR "herbal medicine" OR "medicinal plants" OR turmeric';
      final url =
          '$baseUrl?q=$searchQuery&from=$fromDate&sortBy=publishedAt&language=en&apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;

        // Convert API articles to NewsItem format
        final fetchedNews = articles.take(6).map((article) {
          return _convertToNewsItem(article);
        }).toList();

        setState(() {
          newsItems = fetchedNews;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load news: ${e.toString()}';
        isLoading = false;
        // Fallback to sample data on error
        newsItems = _getSampleNewsItems();
      });
      print('News API Error: $e');
    }
  }

  NewsItem _convertToNewsItem(Map<String, dynamic> article) {
    final title = article['title'] ?? 'No title';
    final description = article['description'] ?? 'No description available';
    final publishedAt = DateTime.parse(article['publishedAt']);
    final source = article['source']['name'] ?? 'Unknown Source';

    return NewsItem(
      title: title,
      summary: description,
      category: _categorizeArticle(title, description),
      timeAgo: _getTimeAgo(publishedAt),
      imageUrl: article['urlToImage'] ?? '',
      isBreaking: _isBreakingNews(publishedAt),
      source: source,
      url: article['url'] ?? '',
      publishedAt: publishedAt,
    );
  }

  String _categorizeArticle(String title, String description) {
    final content = '$title $description'.toLowerCase();

    if (content.contains('research') ||
        content.contains('study') ||
        content.contains('clinical')) {
      return 'Research';
    } else if (content.contains('wellness') ||
        content.contains('health') ||
        content.contains('benefits')) {
      return 'Wellness';
    } else if (content.contains('sustainable') ||
        content.contains('organic') ||
        content.contains('farming')) {
      return 'Sustainability';
    } else if (content.contains('ayurveda') ||
        content.contains('traditional')) {
      return 'Ayurveda';
    } else {
      return 'General';
    }
  }

  String _getTimeAgo(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  bool _isBreakingNews(DateTime publishedAt) {
    final now = DateTime.now();
    return now.difference(publishedAt).inHours < 6;
  }

  List<NewsItem> _getSampleNewsItems() {
    return [
      NewsItem(
        title: "Recent Research on Turmeric's Anti-inflammatory Properties",
        summary:
            "New clinical studies reveal enhanced bioavailability of curcumin when combined with traditional preparation methods.",
        category: "Research",
        timeAgo: "2 hours ago",
        imageUrl: "assets/news/turmeric_research.jpg",
        isBreaking: true,
        source: "Ayurveda Today",
        url: "",
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NewsItem(
        title: "Seasonal Ayurvedic Guidelines for Winter Wellness",
        summary:
            "Traditional practitioners share insights on warming herbs and dietary adjustments for cold season health.",
        category: "Wellness",
        timeAgo: "5 hours ago",
        imageUrl: "assets/news/winter_herbs.jpg",
        isBreaking: false,
        source: "Herbal Medicine Journal",
        url: "",
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            _buildLoadingState()
          else if (errorMessage != null)
            _buildErrorState()
          else
            _buildNewsList(),
          if (!isLoading) _buildViewAllButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: accentGreen),
            SizedBox(height: 16),
            Text(
              'Loading latest Ayurveda news...',
              style: TextStyle(color: darkGray, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.refresh,
            color: Colors.orange.shade400,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Using cached news',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unable to fetch latest updates',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentGreen.withOpacity(0.1),
            lightGreen.withOpacity(0.3),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayurveda News & Research',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? 'Fetching updates...'
                      : 'Latest updates and discoveries',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLoading ? Colors.blue.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isLoading ? 'LOADING' : 'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isLoading ? Colors.blue.shade600 : Colors.red.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    return Column(
      children: newsItems.take(1).map((news) => _buildNewsItem(news)).toList(),
    );
  }

  Widget _buildNewsItem(NewsItem news) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _openNewsDetail(news),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lightGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // News Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      child: news.imageUrl.isNotEmpty &&
                              news.imageUrl.startsWith('http')
                          ? Image.network(
                              news.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: accentGreen.withOpacity(0.2),
                                child: const Icon(
                                  Icons.eco,
                                  color: accentGreen,
                                  size: 24,
                                ),
                              ),
                            )
                          : Container(
                              color: accentGreen.withOpacity(0.2),
                              child: const Icon(
                                Icons.eco,
                                color: accentGreen,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // News Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (news.isBreaking)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BREAKING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                news.category,
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkGray,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          news.summary,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              news.timeAgo,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (news.source.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${news.source}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Add the Open Source button below the news row
              if (news.url.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _launchURL(news.url),
                    icon: const Icon(Icons.link, size: 16, color: accentGreen),
                    label: const Text(
                      'Open Source',
                      style: TextStyle(
                        color: accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

 Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    print("opening $url");
    
    try {
      if (Platform.isAndroid) {
        // For Android, try different approaches
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          // Fallback to platform channel
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        // For iOS and others
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("Error launching URL: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the link: $e')),
      );
    }
  }

  Widget _buildViewAllButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: OutlinedButton(
        onPressed: () => _openAllNews(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: accentGreen, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View All News',
              style: TextStyle(
                color: accentGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              color: accentGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openNewsDetail(NewsItem news) {
    Navigator.pushNamed(context, '/news_detail', arguments: news);
  }

  void _openAllNews() {
    Navigator.pushNamed(context, '/all_news');
  }
}

// Updated NewsItem class with additional fields for API data
class NewsItem {
  final String title;
  final String summary;
  final String category;
  final String timeAgo;
  final String imageUrl;
  final bool isBreaking;
  final String source;
  final String url;
  final DateTime publishedAt;

  NewsItem({
    required this.title,
    required this.summary,
    required this.category,
    required this.timeAgo,
    required this.imageUrl,
    required this.isBreaking,
    required this.source,
    required this.url,
    required this.publishedAt,
  });
}

// Keep existing classes for compatibility
class NewsArticle {
  final NewsSource source;
  final String? author;
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final DateTime publishedAt;
  final String? content;

  NewsArticle({
    required this.source,
    this.author,
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    this.content,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      source: NewsSource.fromJson(json['source']),
      author: json['author'],
      title: json['title'] ?? 'No title',
      description: json['description'],
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      publishedAt: DateTime.parse(json['publishedAt']),
      content: json['content'],
    );
  }
}

class NewsSource {
  final String? id;
  final String name;

  NewsSource({
    this.id,
    required this.name,
  });

  factory NewsSource.fromJson(Map<String, dynamic> json) {
    return NewsSource(
      id: json['id'],
      name: json['name'] ?? 'Unknown Source',
    );
  }
}

// Configuration class for API management
class NewsApiConfig {
  static const String apiKey =
      '20d9ad9e6427488da8a7ead15731859b'; // Your API key is now being used!
  static const String baseUrl = 'https://newsapi.org/v2/everything';

  // Search terms for Ayurveda-related content
  static const List<String> searchTerms = [
    'ayurveda',
    'herbal medicine',
    'medicinal plants',
    'turmeric curcumin',
    'traditional medicine',
    'natural remedies',
    'plant medicine',
    'holistic health',
  ];
}
