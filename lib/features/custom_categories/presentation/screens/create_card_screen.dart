import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/custom_categories/presentation/models/create_card_route_args.dart';

class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key, required this.args});

  final CreateCardRouteArgs args;

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  Difficulty _difficulty = Difficulty.beginner;
  final List<TextEditingController> _guideControllers = <TextEditingController>[];
  final List<_VocabControllers> _vocabControllers = <_VocabControllers>[];

  bool _attemptedSubmit = false;
  bool _saving = false;

  bool get _isEdit => widget.args.existingCard != null;

  @override
  void initState() {
    super.initState();
    final TopicCard? e = widget.args.existingCard;
    _titleController = TextEditingController(text: e?.title ?? '');
    _difficulty = e?.difficulty ?? Difficulty.beginner;
    if (e != null && e.guide.isNotEmpty) {
      for (final String g in e.guide) {
        _guideControllers.add(TextEditingController(text: g));
      }
    } else {
      _guideControllers.add(TextEditingController());
    }
    if (e != null && e.vocabBoost.isNotEmpty) {
      for (final VocabWord v in e.vocabBoost) {
        _vocabControllers.add(
          _VocabControllers(
            word: TextEditingController(text: v.word),
            meaning: TextEditingController(text: v.meaning),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final TextEditingController c in _guideControllers) {
      c.dispose();
    }
    for (final _VocabControllers v in _vocabControllers) {
      v.dispose();
    }
    super.dispose();
  }

  String? _validateTitle(String? v) {
    final String t = (v ?? '').trim();
    if (t.isEmpty) {
      return 'Title is required';
    }
    if (t.length < 10) {
      return 'Use at least 10 characters';
    }
    return null;
  }

  Color _difficultyColor(Difficulty d, ThemeData theme) {
    switch (d) {
      case Difficulty.beginner:
        return theme.brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF22C55E);
      case Difficulty.intermediate:
        return const Color(0xFFF59E0B);
      case Difficulty.advanced:
        return theme.colorScheme.error;
    }
  }

  Future<void> _save() async {
    setState(() => _attemptedSubmit = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String title = _titleController.text.trim();
    final List<String> guide = _guideControllers.map((TextEditingController c) => c.text.trim()).where((String s) => s.isNotEmpty).toList();
    final List<VocabWord> vocab = <VocabWord>[];
    for (final _VocabControllers v in _vocabControllers) {
      final String w = v.word.text.trim();
      final String m = v.meaning.text.trim();
      if (w.isEmpty && m.isEmpty) {
        continue;
      }
      vocab.add(VocabWord(word: w.isEmpty ? '—' : w, meaning: m));
    }

    final String categoryId = widget.args.category.categoryId;
    final String categoryName = widget.args.category.name;

    final TopicCard card = TopicCard(
      cardId: widget.args.existingCard?.cardId ?? 'card_${DateTime.now().microsecondsSinceEpoch}',
      title: title.length > 150 ? title.substring(0, 150) : title,
      category: categoryName,
      difficulty: _difficulty,
      guide: guide,
      vocabBoost: vocab,
      isCustom: true,
      isFavorite: widget.args.existingCard?.isFavorite ?? false,
      createdAt: widget.args.existingCard?.createdAt ?? DateTime.now(),
      customCategoryId: categoryId,
    );

    setState(() => _saving = true);
    final CardRepository repo = context.read<CardRepository>();
    final result = _isEdit ? await repo.updateCustomCard(card) : await repo.addCustomCard(card);

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'Could not save')));
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
        context.pop(true);
      },
    );
  }

  void _addBullet() {
    if (_guideControllers.length >= 5) {
      return;
    }
    setState(() => _guideControllers.add(TextEditingController()));
  }

  void _removeBullet(int i) {
    if (_guideControllers.length <= 1) {
      _guideControllers.first.clear();
      setState(() {});
      return;
    }
    setState(() {
      _guideControllers.removeAt(i).dispose();
    });
  }

  void _addVocab() {
    if (_vocabControllers.length >= 6) {
      return;
    }
    setState(() {
      _vocabControllers.add(_VocabControllers(word: TextEditingController(), meaning: TextEditingController()));
    });
  }

  void _removeVocab(int i) {
    setState(() {
      _vocabControllers.removeAt(i).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Card' : 'New Card'),
        actions: <Widget>[
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: AppSpacing.lg),
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Topic', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _titleController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: const InputDecoration(hintText: 'What will you speak about?', border: InputBorder.none),
                      validator: _validateTitle,
                      autovalidateMode: _attemptedSubmit ? AutovalidateMode.always : AutovalidateMode.disabled,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Difficulty', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<Difficulty>(
                      segments: <ButtonSegment<Difficulty>>[
                        ButtonSegment<Difficulty>(
                          value: Difficulty.beginner,
                          label: Text(
                            'Beginner',
                            style: TextStyle(color: _difficulty == Difficulty.beginner ? _difficultyColor(Difficulty.beginner, theme) : null),
                          ),
                        ),
                        ButtonSegment<Difficulty>(
                          value: Difficulty.intermediate,
                          label: Text(
                            'Intermediate',
                            style: TextStyle(color: _difficulty == Difficulty.intermediate ? _difficultyColor(Difficulty.intermediate, theme) : null),
                          ),
                        ),
                        ButtonSegment<Difficulty>(
                          value: Difficulty.advanced,
                          label: Text(
                            'Advanced',
                            style: TextStyle(color: _difficulty == Difficulty.advanced ? _difficultyColor(Difficulty.advanced, theme) : null),
                          ),
                        ),
                      ],
                      selected: <Difficulty>{_difficulty},
                      onSelectionChanged: (Set<Difficulty> next) {
                        setState(() => _difficulty = next.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Mini guide', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        TextButton(onPressed: _guideControllers.length >= 5 ? null : _addBullet, child: const Text('Add bullet')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Optional tips to structure your talk (max 5).',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _guideControllers.length,
                      onReorder: (int old, int next) {
                        setState(() {
                          if (next > old) {
                            next -= 1;
                          }
                          final TextEditingController c = _guideControllers.removeAt(old);
                          _guideControllers.insert(next, c);
                        });
                      },
                      itemBuilder: (BuildContext context, int i) {
                        final TextEditingController ctrl = _guideControllers[i];
                        return Padding(
                          key: ObjectKey(ctrl),
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ReorderableDragStartListener(
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.md, right: AppSpacing.sm),
                                  child: Icon(Icons.drag_handle_rounded, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: ctrl,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Bullet ${i + 1}',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                  ),
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => _removeBullet(i)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Vocabulary boost', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        TextButton(onPressed: _vocabControllers.length >= 6 ? null : _addVocab, child: const Text('Add word')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Optional word pairs (max 6).', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.md),
                    ...List<Widget>.generate(_vocabControllers.length, (int i) {
                      final _VocabControllers v = _vocabControllers[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: v.word,
                                decoration: const InputDecoration(labelText: 'Word'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextField(
                                controller: v.meaning,
                                decoration: const InputDecoration(labelText: 'Meaning'),
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => _removeVocab(i)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}

class _VocabControllers {
  _VocabControllers({required this.word, required this.meaning});

  final TextEditingController word;
  final TextEditingController meaning;

  void dispose() {
    word.dispose();
    meaning.dispose();
  }
}
