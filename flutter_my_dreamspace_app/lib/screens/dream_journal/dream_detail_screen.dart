import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dream.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_config.dart';

class DreamDetailScreen extends StatefulWidget {
  final Dream dream;

  const DreamDetailScreen({super.key, required this.dream});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  late Dream _dream;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DreamMood _selectedMood;

  final List<Map<String, dynamic>> _moods = [
    {'mood': DreamMood.happy, 'emoji': '😊'},
    {'mood': DreamMood.sad, 'emoji': '😢'},
    {'mood': DreamMood.neutral, 'emoji': '😐'},
    {'mood': DreamMood.excited, 'emoji': '🤩'},
    {'mood': DreamMood.anxious, 'emoji': '😰'},
    {'mood': DreamMood.peaceful, 'emoji': '😌'},
    {'mood': DreamMood.confused, 'emoji': '😕'},
    {'mood': DreamMood.scared, 'emoji': '😱'},
  ];

  @override
  void initState() {
    super.initState();
    _dream = widget.dream;
    _titleController = TextEditingController(text: _dream.title);
    _descController = TextEditingController(text: _dream.description);
    _selectedMood = _dream.mood;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveDream() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedDream = Dream(
        id: _dream.id,
        userId: _dream.userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        mood: _selectedMood,
        createdAt: _dream.createdAt,
      );

      await SupabaseService().updateDream(updatedDream);
      setState(() {
        _dream = updatedDream;
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dream updated')));
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

  Future<void> _deleteDream() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Dream'),
            content: const Text('Are you sure you want to delete this dream?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService().deleteDream(_dream.id);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Dream' : 'Dream Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteDream),
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
                      onPressed: () => setState(() => _errorMessage = null),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child:
                    _isEditing
                        ? Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Title is required';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Title must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                                minLines: 3,
                                maxLines: 6,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'How did you feel?',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                children:
                                    _moods.map((m) {
                                      final selected =
                                          _selectedMood == m['mood'];
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedMood =
                                                m['mood'] as DreamMood;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: AppConfig.shortAnimation,
                                          curve: Curves.easeInOut,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                selected
                                                    ? AppConfig.primaryColor
                                                        .withOpacity(0.15)
                                                    : Colors.transparent,
                                            border: Border.all(
                                              color:
                                                  selected
                                                      ? AppConfig.primaryColor
                                                      : Colors.grey.shade300,
                                              width: selected ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          child: Text(
                                            m['emoji'],
                                            style: TextStyle(
                                              fontSize: 28,
                                              color:
                                                  selected
                                                      ? AppConfig.primaryColor
                                                      : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          _titleController.text = _dream.title;
                                          _descController.text =
                                              _dream.description;
                                          _selectedMood = _dream.mood;
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saveDream,
                                      child: const Text('Save'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'dream-${_dream.id}',
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppConfig.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Center(
                                  child: Text(
                                    _moods.firstWhere(
                                      (m) => m['mood'] == _dream.mood,
                                    )['emoji'],
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _dream.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeFormate(_dream.createdAt.toString()),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                            if (_dream.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                _dream.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ],
                        ),
              ),
    );
  }

  static String timeFormate(var time) {
    DateTime dt1 = DateTime.parse(time.toString());

    return DateFormat("EEE, d MMM yyyy hh:mm a").format(dt1);
  }
}
