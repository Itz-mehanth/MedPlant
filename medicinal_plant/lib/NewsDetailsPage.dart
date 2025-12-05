import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medicinal_plant/YoutubeService.dart';
import 'package:medicinal_plant/Youtube_player_screen.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'AyurvedaNewsWidget.dart';
// News Detail Page
class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGray = Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    final dynamic newsData = ModalRoute.of(context)?.settings.arguments;

    if (newsData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text('Article not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, newsData),
          SliverToBoxAdapter(
            child: _buildArticleContent(context, newsData),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic newsData) {
    String imageUrl = '';
    if (newsData is NewsArticle) {
      imageUrl = newsData.urlToImage ?? '';
    } else if (newsData is NewsItem) {
      imageUrl = newsData.imageUrl;
    }

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: lightGreen,
                    child: const Icon(
                      Icons.article,
                      size: 80,
                      color: primaryGreen,
                    ),
                  ),
                )
              : Container(
                  color: lightGreen,
                  child: const Icon(
                    Icons.article,
                    size: 80,
                    color: primaryGreen,
                  ),
                ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareArticle(newsData),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_browser),
          onPressed: () => _openInBrowser(newsData),
        ),
      ],
    );
  }

  Widget _buildArticleContent(BuildContext context, dynamic newsData) {
    String title = '';
    String description = '';
    String content = '';
    String source = '';
    DateTime? publishedAt;
    String? author;

    if (newsData is NewsArticle) {
      title = newsData.title;
      description = newsData.description ?? '';
      content = newsData.content ?? '';
      source = newsData.source.name;
      publishedAt = newsData.publishedAt;
      author = newsData.author;
    } else if (newsData is NewsItem) {
      title = newsData.title;
      description = newsData.summary;
      content = newsData.summary;
      source = 'PlantCare News';
      author = 'Editorial Team';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article metadata
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        source,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (publishedAt != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                if (author != null && author!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'By $author',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Article content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (content.isNotEmpty && content != description) ...[
                  Text(
                    content.length > 300
                        ? '${content.substring(0, 300)}...\n\nRead full article at source.'
                        : content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: darkGray,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openInBrowser(newsData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_browser,
                          color: Colors.white),
                      label: const Text(
                        'Read Full Article',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  void _shareArticle(dynamic newsData) {
    String url = '';
    String title = '';

    if (newsData is NewsArticle) {
      url = newsData.url;
      title = newsData.title;
    } else if (newsData is NewsItem) {
      title = newsData.title;
      url = 'Check out this article: $title';
    }

    // Implement sharing functionality
    // You can use the share_plus package for this
  }

  void _openInBrowser(dynamic newsData) async {
    String url = '';

    if (newsData is NewsArticle) {
      url = newsData.url;
    }

    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

// All News Page
class AllNewsPage extends StatefulWidget {
  const AllNewsPage({super.key});

  @override
  State<AllNewsPage> createState() => _AllNewsPageState();
}

class _AllNewsPageState extends State<AllNewsPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGray = Color(0xFF2C2C2C);

  List<NewsArticle> _allNews = [];
  List<NewsArticle> _filteredNews = [];
  List<YouTubeVideo> _youtubeVideos = [];
  bool _isLoadingVideos = true;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Ayurveda',
    'Research',
    'Wellness',
    'Sustainability'
  ];

  // Category-specific search terms
  final Map<String, String> _categorySearchTerms = {
    'All': 'ayurveda OR "herbal medicine" OR "medicinal plants" OR turmeric',
    'Ayurveda': 'ayurveda OR "traditional medicine" OR "ancient healing"',
    'Research':
        '"clinical study" OR "research" OR "medical study" AND (herbal OR ayurveda OR "natural medicine")',
    'Wellness':
        'wellness OR "holistic health" OR "natural remedies" AND (herbal OR plant)',
    'Sustainability':
        'sustainable OR organic OR "eco-friendly" AND (farming OR herbs OR plants)',
  };

  @override
  void initState() {
    super.initState();
    _loadAllNews();
    _loadYouTubeVideos();
    _searchController.addListener(_filterNews);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadYouTubeVideos() async {
    setState(() => _isLoadingVideos = true);
    
    try {
      final videos = await YouTubeService.searchAyurvedaVideos();
      setState(() {
        _youtubeVideos = videos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVideos = false;
      });
      print('Error loading YouTube videos: $e');
    }
  }

  Future<void> _loadAllNews() async {
    setState(() => _isLoading = true);

    try {
      const apiKey = NewsApiConfig.apiKey;
      const baseUrl = NewsApiConfig.baseUrl;

      final earliestAllowed = DateTime(2025, 8, 7);
      final calculatedFrom = DateTime.now().subtract(const Duration(days: 7));
      final fromDate = calculatedFrom.isBefore(earliestAllowed)
          ? earliestAllowed.toIso8601String().split('T')[0]
          : calculatedFrom.toIso8601String().split('T')[0];

      // Get search query for selected category
      final searchQuery = _categorySearchTerms[_selectedCategory] ??
          _categorySearchTerms['All']!;
      final url =
          '$baseUrl?q=$searchQuery&from=$fromDate&sortBy=publishedAt&language=en&apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;

        final fetchedNews = articles.map((article) {
          return NewsArticle.fromJson(article);
        }).toList();

        setState(() {
          _allNews = fetchedNews;
          _filteredNews = fetchedNews;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _allNews = [];
        _filteredNews = [];
      });
      print('News API Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load news: ${e.toString()}')),
      );
    }
  }

  void _filterNews() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredNews = _allNews.where((article) {
        final matchesSearch = article.title.toLowerCase().contains(query) ||
            (article.description?.toLowerCase().contains(query) ?? false);

        return matchesSearch;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadAllNews(); // Reload news for the selected category
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text('Ayurveda News',
            style: TextStyle(fontSize: 20, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search news articles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: accentGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) =>
                              _onCategoryChanged(category),
                          backgroundColor: Colors.grey[100],
                          selectedColor: lightGreen,
                          checkmarkColor: primaryGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? primaryGreen : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
       body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : Column(
              children: [
                // YouTube Videos Section
                _buildYouTubeSection(),
                // News Articles Section
                Expanded(
                  child: _filteredNews.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _loadAllNews();
                            await _loadYouTubeVideos();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredNews.length,
                            itemBuilder: (context, index) {
                              return _buildNewsCard(_filteredNews[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAllNews,
            style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewsDetailPage(),
              settings: RouteSettings(arguments: article),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        child: article.urlToImage?.isNotEmpty == true
                            ? Image.network(
                                article.urlToImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: lightGreen,
                                  child: const Icon(Icons.article,
                                      color: primaryGreen),
                                ),
                              )
                            : Container(
                                color: lightGreen,
                                child: const Icon(Icons.article,
                                    color: primaryGreen),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (article.description?.isNotEmpty == true) ...[
                            Text(
                              article.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Text(
                                article.source.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(article.publishedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Add "Open in Browser" button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _launchURL(article.url),
                    icon: const Icon(Icons.open_in_browser,
                        size: 16, color: accentGreen),
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
      ),
    );
  }

  Widget _buildYouTubeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Trending Ayurveda Videos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                const Spacer(),
                if (_isLoadingVideos)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: _isLoadingVideos
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _youtubeVideos.length,
                    itemBuilder: (context, index) {
                      return _buildYouTubeCard(_youtubeVideos[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Add this method for individual YouTube video cards
  Widget _buildYouTubeCard(YouTubeVideo video) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _playYouTubeVideo(video),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.grey[200],
                      child: video.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              video.thumbnailUrl,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Thumbnail error: $error');
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                    // Play button overlay
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Video Info - Fixed height to prevent overflow
            Container(
              height: 85, // Fixed height
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkGray,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.channelTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _formatVideoDate(video.publishedAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  // Add this method to handle video playback
  void _playYouTubeVideo(YouTubeVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubePlayerScreen(video: video),
      ),
    );
  }

  // Add this method for better date formatting for videos
  String _formatVideoDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
