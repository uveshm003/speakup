import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_bloc.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_event.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_state.dart';
import 'package:speakup/features/custom_categories/presentation/widgets/category_editor_sheet.dart';

/// Brand palette accents for category emoji circles (cycles by index).
List<Color> _categoryLeadingColors(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const <Color>[
      AppColorsDark.primary,
      AppColorsDark.primaryDark,
      AppColorsDark.warning,
      AppColorsDark.success,
      AppColorsDark.primaryLight,
      AppColorsDark.error,
    ];
  }
  return const <Color>[
    AppColors.primary,
    AppColors.primaryDark,
    AppColors.warning,
    AppColors.success,
    AppColors.primaryLight,
    AppColors.error,
  ];
}

class MyCategoriesScreen extends StatefulWidget {
  const MyCategoriesScreen({super.key});

  @override
  State<MyCategoriesScreen> createState() => _MyCategoriesScreenState();
}

class _MyCategoriesScreenState extends State<MyCategoriesScreen> {
  void _openEditor({CustomCategory? editing}) {
    showCategoryEditorSheet(context: context, editing: editing);
  }

  void _deleteCategory(CustomCategory cat) {
    context.read<CustomCategoryBloc>().add(CategoryDeleteRequested(cat.categoryId));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Color> palette = _categoryLeadingColors(theme.brightness);

    return BlocListener<CustomCategoryBloc, CustomCategoryState>(
      listenWhen: (CustomCategoryState p, CustomCategoryState c) =>
          c.pendingDeletion != null && c.pendingDeletion != p.pendingDeletion,
      listener: (BuildContext context, CustomCategoryState state) {
        final CustomCategory? cat = state.pendingDeletion;
        if (cat == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${cat.name}"'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context
                    .read<CustomCategoryBloc>()
                    .add(const CategoryDeleteUndoRequested());
              },
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Categories'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'New Category',
              onPressed: () => _openEditor(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Category'),
        ),
        body: BlocBuilder<CustomCategoryBloc, CustomCategoryState>(
          builder: (BuildContext context, CustomCategoryState state) {
            if (state.status == CustomCategoryStatus.loading &&
                state.categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == CustomCategoryStatus.failure &&
                state.categories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    state.errorMessage ?? 'Could not load categories',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (state.categories.isEmpty) {
              return _EmptyState(onCreate: () => _openEditor());
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                88,
              ),
              itemCount: state.categories.length,
              itemBuilder: (BuildContext context, int index) {
                final CustomCategory cat = state.categories[index];
                final Color circleColor = palette[index % palette.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Dismissible(
                    key: ValueKey<String>('cat_${cat.categoryId}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteCategory(cat),
                    child: _CategoryTile(
                      category: cat,
                      circleColor: circleColor,
                      cardCount: state.cardCounts[cat.categoryId] ?? 0,
                      onTap: () {
                        context
                            .push(AppRoutes.categoryDetail, extra: cat)
                            .then((_) {
                          if (context.mounted) {
                            context
                                .read<CustomCategoryBloc>()
                                .add(const CategoriesLoadRequested());
                          }
                        });
                      },
                      onEdit: () => _openEditor(editing: cat),
                      onDelete: () => _deleteCategory(cat),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.folder_special_outlined,
              size: 88,
              color: theme.colorScheme.primary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Create your first category',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add your own topics to practice anything you want — interview questions, debate topics, lesson plans.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create Category'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.circleColor,
    required this.cardCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomCategory category;
  final Color circleColor;
  final int cardCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showMenu(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: circleColor.withValues(alpha: 0.22),
                child: Text(
                  category.iconEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$cardCount cards',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22),
                onPressed: onEdit,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (String value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
