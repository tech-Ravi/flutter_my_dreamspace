import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/dream.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_config.dart';
import 'dream_detail_screen.dart';
import 'add_dream_screen.dart';

class DreamJournalScreen extends StatefulWidget {
  const DreamJournalScreen({super.key});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  List<Dream> _dreams = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreDreams();
    }
  }

  Future<void> _loadDreams() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dreams = await SupabaseService().getDreams(
        limit: _pageSize,
        offset: 0,
      );
      setState(() {
        _dreams = dreams;
        _currentPage = 1;
        _hasMore = dreams.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreDreams() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreDreams = await SupabaseService().getDreams(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      setState(() {
        _dreams.addAll(moreDreams);
        _currentPage++;
        _hasMore = moreDreams.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _shareDream(Dream dream) async {
    HapticFeedback.lightImpact();
    try {
      final shareText = '''
🌟 My Dream from My Dream Space 🌟

Title: ${dream.title}
Mood: ${_getMoodEmoji(dream.mood)} ${dream.mood.toString().split('.').last}

Description:
${dream.description}

Date: ${timeFormate(dream.createdAt.toString())}

Shared from My Dream Space App
''';

      await Share.share(shareText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share dream: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteDream(Dream dream) async {
    try {
      await SupabaseService().deleteDream(dream.id);
      setState(() {
        _dreams.removeWhere((d) => d.id == dream.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dream deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete dream: ${e.toString()}')),
      );
    }
  }

  Future<void> _editDream(Dream dream) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddDreamScreen(dream: dream)),
    );

    if (result == true) {
      try {
        final updatedDream = await SupabaseService().getDreamById(dream.id);
        setState(() {
          final index = _dreams.indexWhere((d) => d.id == dream.id);
          if (index != -1) {
            _dreams[index] = updatedDream;
          }
        });
      } catch (e) {
        // If we can't get the updated dream, reload the entire list
        _loadDreams();
      }
    }
  }

  String _getMoodEmoji(DreamMood mood) {
    switch (mood) {
      case DreamMood.happy:
        return '😊';
      case DreamMood.sad:
        return '😢';
      case DreamMood.neutral:
        return '😐';
      case DreamMood.excited:
        return '🤩';
      case DreamMood.anxious:
        return '😰';
      case DreamMood.peaceful:
        return '😌';
      case DreamMood.confused:
        return '😕';
      case DreamMood.scared:
        return '😱';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dream Journal'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDreams),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDreams,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _dreams.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.nightlight_round,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No dreams logged yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log your first dream to see it here',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadDreams,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppConfig.defaultPadding),
                  itemCount: _dreams.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _dreams.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final dream = _dreams[index];

                    debugPrint(timeFormate(dream.createdAt.toString()));
                    return Dismissible(
                      key: Key(dream.id),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Delete
                          return await showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Dream'),
                                  content: const Text(
                                    'Are you sure you want to delete this dream?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                          );
                        } else if (direction == DismissDirection.startToEnd) {
                          // Edit
                          _editDream(dream);
                          return false; // Don't dismiss the card
                        }
                        return false;
                      },
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          _deleteDream(dream);
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        color: Colors.blue,
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () async {
                            final deleted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        DreamDetailScreen(dream: dream),
                              ),
                            );
                            if (deleted == true) {
                              setState(() {
                                _dreams.removeWhere((d) => d.id == dream.id);
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Hero(
                                      tag: 'dream-${dream.id}',
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppConfig.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getMoodEmoji(dream.mood),
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dream.title,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                          ),
                                          if (dream.description.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              dream.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            timeFormate(
                                              dream.createdAt.toString(),
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () => _shareDream(dream),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  static String timeFormate(var time) {
    DateTime dt1 = DateTime.parse(time.toString());

    return DateFormat("EEE, d MMM yyyy hh:mm a").format(dt1);
  }
}
