import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_bloc.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_event.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_state.dart';

/// Preset emoji row for new/edit category (20 options).
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
];

Future<void> showCategoryEditorSheet({required BuildContext context, CustomCategory? editing}) async {
  final int opBefore = context.read<CustomCategoryBloc>().state.opSeq;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return BlocListener<CustomCategoryBloc, CustomCategoryState>(
        listenWhen: (CustomCategoryState p, CustomCategoryState c) => c.opSeq != p.opSeq || c.errorMessage != p.errorMessage,
        listener: (BuildContext context, CustomCategoryState state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            return;
          }
          if (state.opSeq > opBefore) {
            Navigator.of(context).pop();
          }
        },
        child: _CategoryEditorBody(editing: editing, opBefore: opBefore),
      );
    },
  );
}

class _CategoryEditorBody extends StatefulWidget {
  const _CategoryEditorBody({required this.opBefore, this.editing});

  final CustomCategory? editing;
  final int opBefore;

  @override
  State<_CategoryEditorBody> createState() => _CategoryEditorBodyState();
}

class _CategoryEditorBodyState extends State<_CategoryEditorBody> {
  late String _emoji;
  late final TextEditingController _nameController;

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

  void _save() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
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
    final EdgeInsets pad = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: pad.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.editing != null ? 'Edit Category' : 'New Category',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kCategoryPresetEmojis.length,
                  separatorBuilder: (_, int _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int i) {
                    final String e = kCategoryPresetEmojis[i];
                    final bool sel = e == _emoji;
                    return Material(
                      color: sel ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(() => _emoji = e),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameController,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Category name'),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: _save, child: const Text('Save')),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}
