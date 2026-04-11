import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';

/// Modal bottom sheet for editing the guide bullet points and vocabulary
/// of any card (built-in or custom) in-place.
///
/// Call [show] and await the result — it returns the updated [TopicCard] if
/// the user saved, or `null` if they dismissed without changes.
class EditGuideVocabSheet extends StatefulWidget {
  const EditGuideVocabSheet({super.key, required this.card, required this.repo});

  final TopicCard card;
  final CardRepository repo;

  @override
  State<EditGuideVocabSheet> createState() => _EditGuideVocabSheetState();
}

class _EditGuideVocabSheetState extends State<EditGuideVocabSheet> {
  final List<TextEditingController> _guideControllers = [];
  final List<_VocabPair> _vocabPairs = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill guide
    if (widget.card.guide.isNotEmpty) {
      for (final String g in widget.card.guide) {
        _guideControllers.add(TextEditingController(text: g));
      }
    } else {
      _guideControllers.add(TextEditingController());
    }
    // Pre-fill vocab
    for (final VocabWord v in widget.card.vocabBoost) {
      _vocabPairs.add(
        _VocabPair(
          word: TextEditingController(text: v.word),
          meaning: TextEditingController(text: v.meaning),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _guideControllers) {
      c.dispose();
    }
    for (final _VocabPair v in _vocabPairs) {
      v.dispose();
    }
    super.dispose();
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
    setState(() => _vocabPairs.add(_VocabPair(word: TextEditingController(), meaning: TextEditingController())));
  }

  void _removeVocab(int i) {
    setState(() => _vocabPairs.removeAt(i).dispose());
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _saving = true);

    final List<String> guide = _guideControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    final List<VocabWord> vocab = [];
    for (final _VocabPair v in _vocabPairs) {
      final String w = v.word.text.trim();
      final String m = v.meaning.text.trim();
      if (w.isEmpty && m.isEmpty) continue;
      vocab.add(VocabWord(word: w.isEmpty ? '—' : w, meaning: m));
    }

    final result = await widget.repo.updateCardContent(cardId: widget.card.cardId, guide: guide, vocab: vocab);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message ?? 'Could not save'), backgroundColor: Theme.of(context).colorScheme.error));
      },
      (updated) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(updated);
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration(BuildContext ctx, {required String hint}) {
    final ThemeData t = Theme.of(ctx);
    final bool isDark = t.brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.55), fontSize: 13),
      filled: true,
      fillColor: isDark ? t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : t.colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: t.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: t.colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (BuildContext ctx, ScrollController scrollCtrl) {
        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Guide & Vocabulary', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          widget.card.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              // ── Scrollable content ────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    // ── Mini Guide ───────────────────────────────────────
                    _SectionRow(
                      icon: Icons.list_alt_outlined,
                      title: 'Mini Guide',
                      subtitle: 'Tips to structure your talk (max 5)',
                      canAdd: _guideControllers.length < 5,
                      onAdd: _addBullet,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SectionContainer(
                      isDark: isDark,
                      theme: theme,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: _guideControllers.length,
                        onReorder: (int old, int next) {
                          setState(() {
                            if (next > old) next -= 1;
                            final TextEditingController c = _guideControllers.removeAt(old);
                            _guideControllers.insert(next, c);
                          });
                        },
                        itemBuilder: (_, int i) {
                          final TextEditingController ctrl = _guideControllers[i];
                          return Padding(
                            key: ObjectKey(ctrl),
                            padding: EdgeInsets.only(bottom: i < _guideControllers.length - 1 ? AppSpacing.sm : 0),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: i,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                                  child: Text(
                                    '${i + 1}',
                                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: ctrl,
                                    maxLines: 2,
                                    minLines: 1,
                                    textCapitalization: TextCapitalization.sentences,
                                    style: theme.textTheme.bodyMedium,
                                    decoration: _fieldDecoration(context, hint: 'Bullet point ${i + 1}'),
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

                    // ── Vocabulary Boost ─────────────────────────────────
                    _SectionRow(
                      icon: Icons.spellcheck_rounded,
                      title: 'Vocabulary Boost',
                      subtitle: 'Word/meaning pairs (max 6)',
                      canAdd: _vocabPairs.length < 6,
                      onAdd: _addVocab,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_vocabPairs.isEmpty)
                      _SectionContainer(
                        isDark: isDark,
                        theme: theme,
                        child: InkWell(
                          onTap: _addVocab,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                      _SectionContainer(
                        isDark: isDark,
                        theme: theme,
                        child: Column(
                          children: List.generate(_vocabPairs.length, (int i) {
                            final _VocabPair v = _vocabPairs[i];
                            return Padding(
                              padding: EdgeInsets.only(bottom: i < _vocabPairs.length - 1 ? AppSpacing.md : 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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

                    // ── Save button ──────────────────────────────────────
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section row (title + add button)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.icon, required this.title, required this.subtitle, required this.canAdd, required this.onAdd});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(icon, size: 14, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        if (canAdd)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section container
// ─────────────────────────────────────────────────────────────────────────────
class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.isDark, required this.theme, required this.child});

  final bool isDark;
  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: isDark ? null : [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
