import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AyurvedaQAPage extends StatefulWidget {
  const AyurvedaQAPage({super.key});

  @override
  State<AyurvedaQAPage> createState() => _AyurvedaQAPageState();
}

class _AyurvedaQAPageState extends State<AyurvedaQAPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGray = Color(0xFF2C2C2C);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'All';
  String _sortBy = 'recent'; // recent, popular, unanswered
  
  final List<String> _categories = [
    'All', 'Herbs & Plants', 'Home Remedies', 'Diet & Nutrition', 
    'Treatments', 'Side Effects', 'Research'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionsTab(),
                _buildMyQuestionsTab(),
                _buildMyAnswersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAskQuestionDialog,
        backgroundColor: accentGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ask Question', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      title: const Text('Ayurveda Community'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: primaryGreen,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search questions and answers...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [
                  Tab(text: 'All Questions'),
                  Tab(text: 'My Questions'),
                  Tab(text: 'My Answers'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: lightGreen,
                          checkmarkColor: primaryGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? primaryGreen : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'recent',
                    child: Row(
                      children: [
                        Icon(Icons.access_time),
                        SizedBox(width: 8),
                        Text('Most Recent'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'popular',
                    child: Row(
                      children: [
                        Icon(Icons.trending_up),
                        SizedBox(width: 8),
                        Text('Most Popular'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'unanswered',
                    child: Row(
                      children: [
                        Icon(Icons.help_outline),
                        SizedBox(width: 8),
                        Text('Unanswered'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getQuestionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentGreen));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No questions found', 'Be the first to ask a question!');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final question = Question.fromFirestore(snapshot.data!.docs[index]);
            return _buildQuestionCard(question);
          },
        );
      },
    );
  }

  Widget _buildMyQuestionsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState('Please login', 'Login to view your questions');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('questions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentGreen));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No questions yet', 'Ask your first question about Ayurveda!');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final question = Question.fromFirestore(snapshot.data!.docs[index]);
            return _buildQuestionCard(question, showActions: true);
          },
        );
      },
    );
  }

  Widget _buildMyAnswersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState('Please login', 'Login to view your answers');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('answers')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentGreen));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No answers yet', 'Start helping the community by answering questions!');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final answerDoc = snapshot.data!.docs[index];
            return _buildAnswerCard(answerDoc);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, {bool showActions = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openQuestionDetail(question),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(question.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (question.isSolved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SOLVED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                question.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${question.upvotes}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${question.answersCount}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${question.views}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(question.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: primaryGreen,
                    child: Text(
                      question.userName.isNotEmpty ? question.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    question.userName.isNotEmpty ? question.userName : 'Anonymous',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showActions) ...[
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleQuestionAction(value, question),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerCard(QueryDocumentSnapshot answerDoc) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('questions')
          .doc(answerDoc['questionId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final questionData = snapshot.data!.data() as Map<String, dynamic>?;
        if (questionData == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answered: ${questionData['title']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  answerDoc['content'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${answerDoc['upvotes'] ?? 0}', 
                         style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const Spacer(),
                    Text(
                      _formatDate((answerDoc['createdAt'] as Timestamp).toDate()),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getQuestionsStream() {
    Query query = FirebaseFirestore.instance.collection('questions');
    
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    if (_searchController.text.isNotEmpty) {
      query = query.where('searchKeywords', arrayContains: _searchController.text.toLowerCase());
    }
    
    switch (_sortBy) {
      case 'popular':
        query = query.orderBy('upvotes', descending: true);
        break;
      case 'unanswered':
        query = query.where('answersCount', isEqualTo: 0).orderBy('createdAt', descending: true);
        break;
      default:
        query = query.orderBy('createdAt', descending: true);
    }
    
    return query.snapshots();
  }

  void _showAskQuestionDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AskQuestionPage()),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to ask questions and participate in discussions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login page
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _openQuestionDetail(Question question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionDetailPage(question: question),
      ),
    );
  }

  void _handleQuestionAction(String action, Question question) {
    switch (action) {
      case 'edit':
        // Navigate to edit question page
        break;
      case 'delete':
        _showDeleteConfirmation(question);
        break;
    }
  }

  void _showDeleteConfirmation(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteQuestion(question);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(Question question) async {
    try {
      await FirebaseFirestore.instance.collection('questions').doc(question.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting question: $e')),
      );
    }
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Herbs & Plants': Colors.green,
      'Home Remedies': Colors.blue,
      'Diet & Nutrition': Colors.orange,
      'Treatments': Colors.purple,
      'Side Effects': Colors.red,
      'Research': Colors.teal,
    };
    return colors[category] ?? Colors.grey;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

// Question model
class Question {
  final String id;
  final String title;
  final String description;
  final String category;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final int answersCount;
  final int views;
  final bool isSolved;
  final List<String> tags;
  final List<String> searchKeywords;

  Question({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.answersCount = 0,
    this.views = 0,
    this.isSolved = false,
    this.tags = const [],
    this.searchKeywords = const [],
  });

  factory Question.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      answersCount: data['answersCount'] ?? 0,
      views: data['views'] ?? 0,
      isSolved: data['isSolved'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
    );
  }
}

// Ask Question Page
class AskQuestionPage extends StatefulWidget {
  const AskQuestionPage({super.key});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'General';
  final List<String> _categories = [
    'General', 'Herbs & Plants', 'Home Remedies', 'Diet & Nutrition', 
    'Treatments', 'Side Effects', 'Research'
  ];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ask a Question'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical Disclaimer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This community is for educational and informational purposes only. Always consult with qualified healthcare professionals for medical advice. Do not rely solely on information from this platform for health decisions.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Question Title',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'What is your question about Ayurveda or medicinal plants?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: accentGreen),
                  ),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a question title';
                  }
                  if (value.trim().length < 10) {
                    return 'Title must be at least 10 characters long';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: accentGreen),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Detailed Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Provide detailed information about your question, symptoms, current treatments, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: accentGreen),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a detailed description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters long';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post Question',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      // Create search keywords for better searchability
      final searchKeywords = [
        ...title.toLowerCase().split(' '),
        ...description.toLowerCase().split(' '),
        _selectedCategory.toLowerCase(),
      ].where((word) => word.length > 2).toList();

      await FirebaseFirestore.instance.collection('questions').add({
        'title': title,
        'description': description,
        'category': _selectedCategory,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
        'answersCount': 0,
        'views': 0,
        'isSolved': false,
        'tags': [],
        'searchKeywords': searchKeywords,
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question posted successfully!'),
            backgroundColor: accentGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// Question Detail Page
class QuestionDetailPage extends StatefulWidget {
  final Question question;

  const QuestionDetailPage({super.key, required this.question});

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGray = Color(0xFF2C2C2C);

  final TextEditingController _answerController = TextEditingController();
  bool _isSubmittingAnswer = false;
  bool _hasUpvoted = false;
  bool _hasDownvoted = false;

  @override
  void initState() {
    super.initState();
    _incrementViewCount();
    _checkUserVoteStatus();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _incrementViewCount() async {
    try {
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.question.id)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  Future<void> _checkUserVoteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final voteDoc = await FirebaseFirestore.instance
          .collection('votes')
          .where('userId', isEqualTo: user.uid)
          .where('questionId', isEqualTo: widget.question.id)
          .where('type', isEqualTo: 'question')
          .get();

      if (voteDoc.docs.isNotEmpty) {
        final voteData = voteDoc.docs.first.data();
        setState(() {
          _hasUpvoted = voteData['isUpvote'] == true;
          _hasDownvoted = voteData['isUpvote'] == false;
        });
      }
    } catch (e) {
      print('Error checking vote status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Question Details'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQuestion,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuestionHeader(),
                  _buildAnswersSection(),
                ],
              ),
            ),
          ),
          _buildAnswerInputSection(),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.question.category),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.question.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.question.isSolved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SOLVED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.question.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkGray,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.question.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryGreen,
                child: Text(
                  widget.question.userName.isNotEmpty 
                      ? widget.question.userName[0].toUpperCase() 
                      : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question.userName.isNotEmpty 
                          ? widget.question.userName 
                          : 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Asked ${_formatDate(widget.question.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildVoteButton(
                icon: Icons.thumb_up_outlined,
                count: widget.question.upvotes,
                isActive: _hasUpvoted,
                onTap: () => _voteQuestion(true),
              ),
              const SizedBox(width: 16),
              _buildVoteButton(
                icon: Icons.thumb_down_outlined,
                count: widget.question.downvotes,
                isActive: _hasDownvoted,
                onTap: () => _voteQuestion(false),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.question.views} views',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? accentGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accentGreen : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? accentGreen : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: isActive ? accentGreen : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Answers (${widget.question.answersCount})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('answers')
                .where('questionId', isEqualTo: widget.question.id)
                .orderBy('upvotes', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: accentGreen),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No answers yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to help by providing an answer!',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return _buildAnswerCard(doc);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(QueryDocumentSnapshot answerDoc) {
    final answerData = answerDoc.data() as Map<String, dynamic>;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentGreen,
                child: Text(
                  (answerData['userName'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answerData['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Answered ${_formatDate((answerData['createdAt'] as Timestamp).toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (answerData['isBestAnswer'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BEST ANSWER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answerData['content'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAnswerVoteButton(
                icon: Icons.thumb_up_outlined,
                count: answerData['upvotes'] ?? 0,
                answerId: answerDoc.id,
                isUpvote: true,
              ),
              const SizedBox(width: 12),
              _buildAnswerVoteButton(
                icon: Icons.thumb_down_outlined,
                count: answerData['downvotes'] ?? 0,
                answerId: answerDoc.id,
                isUpvote: false,
              ),
              const Spacer(),
              if (widget.question.userId == FirebaseAuth.instance.currentUser?.uid)
                TextButton.icon(
                  onPressed: () => _markAsBestAnswer(answerDoc.id),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Best Answer', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: accentGreen),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerVoteButton({
    required IconData icon,
    required int count,
    required String answerId,
    required bool isUpvote,
  }) {
    return InkWell(
      onTap: () => _voteAnswer(answerId, isUpvote),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInputSection() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text('Please login to post an answer'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to login
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Answer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            decoration: InputDecoration(
              hintText: 'Share your knowledge and help the community...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: accentGreen),
              ),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                onPressed: _isSubmittingAnswer ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmittingAnswer
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Post Answer',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer() async {
    final content = _answerController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
      return;
    }

    setState(() {
      _isSubmittingAnswer = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      await FirebaseFirestore.instance.collection('answers').add({
        'questionId': widget.question.id,
        'content': content,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
        'isBestAnswer': false,
      });

      // Update question answer count
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(widget.question.id)
          .update({'answersCount': FieldValue.increment(1)});

      _answerController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer posted successfully!'),
          backgroundColor: accentGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting answer: $e')),
      );
    } finally {
      setState(() {
        _isSubmittingAnswer = false;
      });
    }
  }

  Future<void> _voteQuestion(bool isUpvote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    try {
      final voteRef = FirebaseFirestore.instance.collection('votes').doc();
      
      // First, get the existing vote document (if any) outside the transaction
      final existingVoteQuery = await FirebaseFirestore.instance
          .collection('votes')
          .where('userId', isEqualTo: user.uid)
          .where('questionId', isEqualTo: widget.question.id)
          .where('type', isEqualTo: 'question')
          .limit(1)
          .get();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final questionRef = FirebaseFirestore.instance
            .collection('questions')
            .doc(widget.question.id);

        if (existingVoteQuery.docs.isNotEmpty) {
          // User already voted, remove old vote
          final oldVoteDoc = existingVoteQuery.docs.first;
          final oldVoteData = oldVoteDoc.data() as Map<String, dynamic>;

          transaction.delete(oldVoteDoc.reference);

          if (oldVoteData['isUpvote'] == true) {
            transaction.update(questionRef, {'upvotes': FieldValue.increment(-1)});
          } else {
            transaction.update(questionRef, {'downvotes': FieldValue.increment(-1)});
          }
        }

        // Add new vote if different from existing
        if (existingVoteQuery.docs.isEmpty ||
            (existingVoteQuery.docs.first.data() as Map<String, dynamic>)['isUpvote'] != isUpvote) {
          transaction.set(voteRef, {
            'userId': user.uid,
            'questionId': widget.question.id,
            'type': 'question',
            'isUpvote': isUpvote,
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (isUpvote) {
            transaction.update(questionRef, {'upvotes': FieldValue.increment(1)});
          } else {
            transaction.update(questionRef, {'downvotes': FieldValue.increment(1)});
          }
        }
      });

      setState(() {
        _hasUpvoted = isUpvote;
        _hasDownvoted = !isUpvote;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voting: $e')),
      );
    }
  }

  Future<void> _voteAnswer(String answerId, bool isUpvote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    try {
      final voteRef = FirebaseFirestore.instance.collection('votes').doc();
      
      // First, get the existing vote document (if any) outside the transaction
      final existingVoteQuery = await FirebaseFirestore.instance
          .collection('votes')
          .where('userId', isEqualTo: user.uid)
          .where('answerId', isEqualTo: answerId)
          .where('type', isEqualTo: 'answer')
          .limit(1)
          .get();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final answerRef = FirebaseFirestore.instance
            .collection('answers')
            .doc(answerId);

        if (existingVoteQuery.docs.isNotEmpty) {
          final oldVoteDoc = existingVoteQuery.docs.first;
          final oldVoteData = oldVoteDoc.data() as Map<String, dynamic>;

          transaction.delete(oldVoteDoc.reference);

          if (oldVoteData['isUpvote'] == true) {
            transaction.update(answerRef, {'upvotes': FieldValue.increment(-1)});
          } else {
            transaction.update(answerRef, {'downvotes': FieldValue.increment(-1)});
          }
        }

        if (existingVoteQuery.docs.isEmpty ||
            (existingVoteQuery.docs.first.data() as Map<String, dynamic>)['isUpvote'] != isUpvote) {
          transaction.set(voteRef, {
            'userId': user.uid,
            'answerId': answerId,
            'type': 'answer',
            'isUpvote': isUpvote,
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (isUpvote) {
            transaction.update(answerRef, {'upvotes': FieldValue.increment(1)});
          } else {
            transaction.update(answerRef, {'downvotes': FieldValue.increment(1)});
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voting: $e')),
      );
    }
  }

  Future<void> _markAsBestAnswer(String answerId) async {
    try {
      // Fetch all answers for this question first (outside the transaction)
      final otherAnswersSnapshot = await FirebaseFirestore.instance
          .collection('answers')
          .where('questionId', isEqualTo: widget.question.id)
          .get();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Remove best answer from all other answers for this question
        for (final doc in otherAnswersSnapshot.docs) {
          transaction.update(doc.reference, {'isBestAnswer': false});
        }

        // Mark this answer as best
        transaction.update(
          FirebaseFirestore.instance.collection('answers').doc(answerId),
          {'isBestAnswer': true},
        );

        // Mark question as solved
        transaction.update(
          FirebaseFirestore.instance.collection('questions').doc(widget.question.id),
          {'isSolved': true},
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer marked as best answer!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking best answer: $e')),
      );
    }
  }

  void _shareQuestion() {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality coming soon!')),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to vote on questions and answers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login page
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Herbs & Plants': Colors.green,
      'Home Remedies': Colors.blue,
      'Diet & Nutrition': Colors.orange,
      'Treatments': Colors.purple,
      'Side Effects': Colors.red,
      'Research': Colors.teal,
    };
    return colors[category] ?? Colors.grey;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}