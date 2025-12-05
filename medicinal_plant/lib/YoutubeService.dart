import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeService {
  static const String _apiKey = 'AIzaSyBsZw9AKNFhus-5U4-DzM7ULWfU8bAg4vw'; // Replace with your API key
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3/search';

  static Future<List<YouTubeVideo>> searchAyurvedaVideos() async {
    try {
      final query = 'ayurveda OR "herbal medicine" OR "medicinal plants" OR "natural healing"';
      final url = '$_baseUrl?part=snippet&type=video&q=$query&maxResults=10&order=viewCount&publishedAfter=${_getLastWeekDate()}&key=$_apiKey';

      print('YouTube API URL: $url'); // Debug line

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: ${data['items']?.length ?? 0} items'); // Debug line
        
        final items = data['items'] as List;

        return items.map((item) {
          final video = YouTubeVideo.fromJson(item);
          print('Video: ${video.title}'); // Debug line
          print('Thumbnail: ${video.thumbnailUrl}'); // Debug line
          return video;
        }).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}'); // Debug line
        throw Exception('Failed to load YouTube videos: ${response.statusCode}');
      }
    } catch (e) {
      print('YouTube API Error: $e');
      return _getFallbackVideos();
    }
  }

  static String _getLastWeekDate() {
    final now = DateTime.now().toUtc();
    final lastWeek = now.subtract(const Duration(days: 30));

    // Use milliseconds precision, not microseconds/nanoseconds
    return lastWeek.toIso8601String().split('.').first + "Z";
  }



  static List<YouTubeVideo> _getFallbackVideos() {
    return [
      YouTubeVideo(
        id: 'sample1',
        title: 'The Science Behind Ayurvedic Medicine',
        channelTitle: 'Wellness Channel',
        thumbnailUrl: '',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      YouTubeVideo(
        id: 'sample2',
        title: 'Top 10 Medicinal Plants for Home Remedies',
        channelTitle: 'Herbal Medicine Today',
        thumbnailUrl: '',
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}

class YouTubeVideo {
  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final DateTime publishedAt;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    final thumbnails = snippet['thumbnails'];
    
    // Try different thumbnail qualities
    String thumbnailUrl = '';
    if (thumbnails['high'] != null) {
      thumbnailUrl = thumbnails['high']['url'];
    } else if (thumbnails['medium'] != null) {
      thumbnailUrl = thumbnails['medium']['url'];
    } else if (thumbnails['default'] != null) {
      thumbnailUrl = thumbnails['default']['url'];
    }
    
    return YouTubeVideo(
      id: json['id']['videoId'],
      title: snippet['title'],
      channelTitle: snippet['channelTitle'],
      thumbnailUrl: thumbnailUrl,
      publishedAt: DateTime.parse(snippet['publishedAt']),
    );
  }

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$id';
}