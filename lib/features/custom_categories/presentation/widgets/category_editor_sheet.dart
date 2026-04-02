import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_bloc.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_event.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_state.dart';

/// 24 carefully chosen preset emojis for category icons.
const List<String> kCategoryPresetEmojis = <String>[
  '📚',
  '💡',
  '🎯',
  '🌟',
  '💼',
  '🔬',
  '🎨',
  '🏋️',
  '🧠',
  '📝',
  '🌍',
  '💬',
  '🎤',
  '🚀',
  '🎓',
  '✨',
  '💪',
  '📌',
  '🎭',
  '🔥',
  '🏆',
  '🎵',
  '🌱',
  '⚡',
];

Future<void> showCategoryEditorSheet({required BuildContext context, CustomCategory? editing}) async {
  // Capture the bloc reference BEFORE entering the sheet to avoid
  // looking up an ancestor through a stale BuildContext.
  final CustomCategoryBloc bloc = context.read<CustomCategoryBloc>();
  final int opBefore = bloc.state.opSeq;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (BuildContext sheetContext) {
      // Inject the already-resolved bloc so the sheet's BuildContext
      // is never used to walk up to the route-level provider.
      return BlocProvider<CustomCategoryBloc>.value(
        value: bloc,
        child: BlocListener<CustomCategoryBloc, CustomCategoryState>(
          listenWhen: (CustomCategoryState p, CustomCategoryState c) => c.opSeq != p.opSeq || c.errorMessage != p.errorMessage,
          listener: (BuildContext ctx, CustomCategoryState state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              return;
            }
            if (state.opSeq > opBefore) {
              Navigator.of(ctx).pop();
            }
          },
          child: _CategoryEditorBody(editing: editing),
        ),
      );
    },
  );
}

class _CategoryEditorBody extends StatefulWidget {
  const _CategoryEditorBody({this.editing});

  final CustomCategory? editing;

  @override
  State<_CategoryEditorBody> createState() => _CategoryEditorBodyState();
}

class _CategoryEditorBodyState extends State<_CategoryEditorBody> {
  late String _emoji;
  late final TextEditingController _nameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emoji = widget.editing?.iconEmoji ?? kCategoryPresetEmojis.first;
    _nameController = TextEditingController(text: widget.editing?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final String t = (v ?? '').trim();
    if (t.isEmpty) return 'Give your category a name';
    if (t.length < 2) return 'At least 2 characters';
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final String name = _nameController.text.trim();
    final CustomCategoryBloc bloc = context.read<CustomCategoryBloc>();

    if (widget.editing != null) {
      bloc.add(
        CategoryUpdateRequested(
          CustomCategory(
            categoryId: widget.editing!.categoryId,
            name: name.length > 30 ? name.substring(0, 30) : name,
            iconEmoji: _emoji,
            createdAt: widget.editing!.createdAt,
          ),
        ),
      );
    } else {
      bloc.add(CategoryCreateRequested(name: name, emoji: _emoji));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xs, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: <Widget>[
                  // Large emoji preview
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.editing != null ? 'Edit Category' : 'New Category',
                          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.editing != null ? 'Update name or icon' : 'Pick an icon and a name',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Emoji picker ─────────────────────────────────────────────
              Text(
                'Icon',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kCategoryPresetEmojis.length,
                  separatorBuilder: (_, int __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (BuildContext ctx, int i) {
                    final String e = kCategoryPresetEmojis[i];
                    final bool selected = e == _emoji;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primaryContainer
                            : (isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerLow),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: selected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _emoji = e),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Name field ───────────────────────────────────────────────
              Text(
                'Name',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. Interview Questions',
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : theme.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: theme.colorScheme.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                validator: _validateName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Action buttons ───────────────────────────────────────────
              BlocBuilder<CustomCategoryBloc, CustomCategoryState>(
                builder: (BuildContext ctx, CustomCategoryState st) {
                  final bool busy = _submitting && st.status == CustomCategoryStatus.loading;
                  return FilledButton(
                    onPressed: busy ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                    child: busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.editing != null ? 'Save Changes' : 'Create Category', style: const TextStyle(fontWeight: FontWeight.w700)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
