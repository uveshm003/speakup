import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/custom_categories/presentation/models/create_card_route_args.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit card screen
// ─────────────────────────────────────────────────────────────────────────────

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

  // Guide bullets — at least 1 always present
  final List<TextEditingController> _guideControllers = <TextEditingController>[];

  // Vocabulary word/meaning pairs
  final List<_VocabPair> _vocabPairs = <_VocabPair>[];

  bool _attemptedSubmit = false;
  bool _saving = false;

  bool get _isEdit => widget.args.existingCard != null;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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
        _vocabPairs.add(
          _VocabPair(
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
    for (final _VocabPair v in _vocabPairs) {
      v.dispose();
    }
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateTitle(String? v) {
    final String t = (v ?? '').trim();
    if (t.isEmpty) return 'Topic title is required';
    if (t.length < 10) return 'Use at least 10 characters';
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _attemptedSubmit = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() => _saving = true);

    final String title = _titleController.text.trim();
    final List<String> guide = _guideControllers.map((TextEditingController c) => c.text.trim()).where((String s) => s.isNotEmpty).toList();

    final List<VocabWord> vocab = <VocabWord>[];
    for (final _VocabPair v in _vocabPairs) {
      final String w = v.word.text.trim();
      final String m = v.meaning.text.trim();
      if (w.isEmpty && m.isEmpty) continue;
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

    if (!mounted) return;
    final CardRepository repo = context.read<CardRepository>();
    final result = _isEdit ? await repo.updateCustomCard(card) : await repo.addCustomCard(card);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message ?? 'Could not save card'), backgroundColor: Theme.of(context).colorScheme.error));
      },
      (_) {
        HapticFeedback.mediumImpact();
        context.pop(true);
      },
    );
  }

  // ── Guide helpers ─────────────────────────────────────────────────────────

  void _addBullet() {
    if (_guideControllers.length >= 5) return;
    setState(() => _guideControllers.add(TextEditingController()));
  }

  void _removeBullet(int i) {
    if (_guideControllers.length <= 1) {
      _guideControllers.first.clear();
      setState(() {});
      return;
    }
    setState(() => _guideControllers.removeAt(i).dispose());
  }

  // ── Vocab helpers ─────────────────────────────────────────────────────────

  void _addVocab() {
    if (_vocabPairs.length >= 6) return;
    setState(() {
      _vocabPairs.add(_VocabPair(word: TextEditingController(), meaning: TextEditingController()));
    });
  }

  void _removeVocab(int i) {
    setState(() => _vocabPairs.removeAt(i).dispose());
  }

  // ── Theme helpers ─────────────────────────────────────────────────────────

  Color _difficultyColor(Difficulty d) {
    final ThemeData theme = Theme.of(context);
    switch (d) {
      case Difficulty.beginner:
        return theme.brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF22C55E);
      case Difficulty.intermediate:
        return const Color(0xFFF59E0B);
      case Difficulty.advanced:
        return theme.colorScheme.error;
    }
  }

  IconData _difficultyIcon(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:
        return Icons.eco_outlined;
      case Difficulty.intermediate:
        return Icons.trending_up_rounded;
      case Difficulty.advanced:
        return Icons.local_fire_department_outlined;
    }
  }

  String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:
        return 'Beginner';
      case Difficulty.intermediate:
        return 'Intermediate';
      case Difficulty.advanced:
        return 'Advanced';
    }
  }

  InputDecoration _fieldDecoration(BuildContext ctx, {required String hint}) {
    final ThemeData theme = Theme.of(ctx);
    final bool isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55), fontSize: 14),
      filled: true,
      fillColor: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : theme.colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        scrolledUnderElevation: 1,
        title: Row(
          children: <Widget>[
            Text(widget.args.category.iconEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(_isEdit ? 'Edit Card' : 'New Card', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(
                    widget.args.category.name,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.huge),
          children: <Widget>[
            // ═══════════════════════════════════════════════════════════
            // 1. Topic
            // ═══════════════════════════════════════════════════════════
            _SectionHeader(icon: Icons.article_outlined, title: 'Topic', subtitle: 'What will you speak about?'),
            const SizedBox(height: AppSpacing.sm),
            _SectionCard(
              child: TextFormField(
                controller: _titleController,
                maxLines: 4,
                minLines: 2,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15, height: 1.5),
                decoration: _fieldDecoration(
                  context,
                  hint: 'e.g. Describe a challenge that changed your perspective…',
                ).copyWith(counterStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                validator: _validateTitle,
                autovalidateMode: _attemptedSubmit ? AutovalidateMode.always : AutovalidateMode.disabled,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ═══════════════════════════════════════════════════════════
            // 2. Difficulty
            // ═══════════════════════════════════════════════════════════
            _SectionHeader(icon: Icons.bar_chart_rounded, title: 'Difficulty'),
            const SizedBox(height: AppSpacing.sm),
            _SectionCard(
              child: Row(
                children: Difficulty.values.map((Difficulty d) {
                  final bool selected = _difficulty == d;
                  final Color color = _difficultyColor(d);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _difficulty = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: d != Difficulty.advanced ? const EdgeInsets.only(right: AppSpacing.xs) : EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: selected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Icon(_difficultyIcon(d), color: selected ? color : theme.colorScheme.onSurfaceVariant, size: 20),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _difficultyLabel(d),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? color : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ═══════════════════════════════════════════════════════════
            // 3. Mini guide
            // ═══════════════════════════════════════════════════════════
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: _SectionHeader(icon: Icons.list_alt_outlined, title: 'Mini Guide', subtitle: 'Optional tips to structure your talk (max 5)'),
                ),
                if (_guideControllers.length < 5)
                  TextButton.icon(
                    onPressed: _addBullet,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SectionCard(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _guideControllers.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final TextEditingController c = _guideControllers.removeAt(oldIndex);
                    _guideControllers.insert(newIndex, c);
                  });
                },
                itemBuilder: (BuildContext ctx, int i) {
                  final TextEditingController ctrl = _guideControllers[i];
                  return Padding(
                    key: ObjectKey(ctrl),
                    padding: EdgeInsets.only(bottom: i < _guideControllers.length - 1 ? AppSpacing.sm : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Icon(Icons.drag_handle_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45), size: 20),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            maxLines: 2,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.bodyMedium,
                            decoration: _fieldDecoration(ctx, hint: 'Bullet point ${i + 1}'),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20,
                            color: _guideControllers.length <= 1
                                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                                : theme.colorScheme.error.withValues(alpha: 0.7),
                          ),
                          onPressed: () => _removeBullet(i),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ═══════════════════════════════════════════════════════════
            // 4. Vocabulary boost
            // ═══════════════════════════════════════════════════════════
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: _SectionHeader(icon: Icons.spellcheck_rounded, title: 'Vocabulary Boost', subtitle: 'Optional word pairs (max 6)'),
                ),
                if (_vocabPairs.length < 6)
                  TextButton.icon(
                    onPressed: _addVocab,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_vocabPairs.isEmpty)
              _SectionCard(
                child: InkWell(
                  onTap: _addVocab,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Add vocabulary words',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _SectionCard(
                child: Column(
                  children: List<Widget>.generate(_vocabPairs.length, (int i) {
                    final _VocabPair v = _vocabPairs[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < _vocabPairs.length - 1 ? AppSpacing.md : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: v.word,
                              textCapitalization: TextCapitalization.words,
                              style: theme.textTheme.bodyMedium,
                              decoration: _fieldDecoration(context, hint: 'Word'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: v.meaning,
                              textCapitalization: TextCapitalization.sentences,
                              style: theme.textTheme.bodyMedium,
                              decoration: _fieldDecoration(context, hint: 'Meaning'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: theme.colorScheme.error.withValues(alpha: 0.7)),
                            onPressed: () => _removeVocab(i),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Bottom save button ────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save Changes' : 'Create Card', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header widget
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
            if (subtitle != null) Text(subtitle!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card container
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: isDark
            ? null
            : <BoxShadow>[BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vocab pair controller holder
// ─────────────────────────────────────────────────────────────────────────────
class _VocabPair {
  _VocabPair({required this.word, required this.meaning});

  final TextEditingController word;
  final TextEditingController meaning;

  void dispose() {
    word.dispose();
    meaning.dispose();
  }
}
