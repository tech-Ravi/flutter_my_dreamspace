import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dream.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DreamLogScreen extends ConsumerStatefulWidget {
  const DreamLogScreen({super.key});

  @override
  ConsumerState<DreamLogScreen> createState() => _DreamLogScreenState();
}

class _DreamLogScreenState extends ConsumerState<DreamLogScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DreamMood? _selectedMood;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _successController;
  late Animation<double> _successScale;

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
    _buttonController = AnimationController(
      vsync: this,
      duration: AppConfig.shortAnimation,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _buttonController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedMood == null) {
     //for UX
      HapticFeedback.mediumImpact();
      
      setState(() {
        _errorMessage = _selectedMood == null ? 'Please select a mood.' : null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = SupabaseService().currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'User not authenticated.';
        });
        return;
      }
      final dream = Dream(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        mood: _selectedMood!,
      );
      await SupabaseService().createDream(dream);
      _titleController.clear();
      _descController.clear();
      setState(() {
        _selectedMood = null;
        _isSuccess = true;
      });
      _successController.forward();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _successController.reverse();
        setState(() {
          _isSuccess = false;
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onButtonTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _buttonController.forward();
  }

  void _onButtonTapUp(TapUpDetails details) {
    _buttonController.reverse();
  }

  void _onButtonTapCancel() {
    _buttonController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a Dream')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Dream Title',
                      prefixIcon: Icon(Icons.title),
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
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
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
                          final selected = _selectedMood == m['mood'];
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedMood = m['mood'] as DreamMood;
                                _errorMessage = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppConfig.shortAnimation,
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? AppConfig.primaryColor.withOpacity(
                                          0.15,
                                        )
                                        : Colors.transparent,
                                border: Border.all(
                                  color:
                                      selected
                                          ? AppConfig.primaryColor
                                          : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                m['emoji'],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTapDown: _onButtonTapDown,
                    onTapUp: _onButtonTapUp,
                    onTapCancel: _onButtonTapCancel,
                    child: ScaleTransition(
                      scale: _buttonScale,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Log Dream'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSuccess)
            ScaleTransition(
              scale: _successScale,
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Dream logged successfully!',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
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
}
