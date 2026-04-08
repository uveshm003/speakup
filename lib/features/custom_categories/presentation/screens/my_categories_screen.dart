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

/// Cycling accent colours for category cards.
List<Color> _palette(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const <Color>[
      AppColorsDark.primary,
      AppColorsDark.warning,
      AppColorsDark.success,
      AppColorsDark.primaryDark,
      AppColorsDark.primaryLight,
      AppColorsDark.error,
    ];
  }
  return const <Color>[AppColors.primary, AppColors.warning, AppColors.success, AppColors.primaryDark, AppColors.primaryLight, AppColors.error];
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
    final List<Color> palette = _palette(theme.brightness);
    final bool isDark = theme.brightness == Brightness.dark;

    return BlocListener<CustomCategoryBloc, CustomCategoryState>(
      listenWhen: (CustomCategoryState p, CustomCategoryState c) => c.pendingDeletion != null && c.pendingDeletion != p.pendingDeletion,
      listener: (BuildContext ctx, CustomCategoryState state) {
        final CustomCategory? cat = state.pendingDeletion;
        if (cat == null) return;
        ScaffoldMessenger.of(ctx).clearSnackBars();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Deleted "${cat.name}"'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read<CustomCategoryBloc>().add(const CategoryDeleteUndoRequested());
              },
            ),
          ),
        );
      },
      child: Scaffold(
        body: BlocBuilder<CustomCategoryBloc, CustomCategoryState>(
          builder: (BuildContext ctx, CustomCategoryState state) {
            return CustomScrollView(
              slivers: <Widget>[
                // ── Gradient SliverAppBar ───────────────────────────────
                SliverAppBar(
                  expandedHeight: 160,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.primary,
                  foregroundColor: isDark ? theme.colorScheme.onSurface : Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                    title: Text(
                      'My Categories',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: isDark ? theme.colorScheme.onSurface : Colors.white,
                      ),
                    ),
                    background: _AppBarBackground(isDark: isDark, theme: theme),
                  ),
                  actions: <Widget>[
                    IconButton(icon: const Icon(Icons.add_rounded), tooltip: 'New Category', onPressed: () => _openEditor()),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),

                // ── Stats strip ────────────────────────────────────────
                if (state.categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _StatsStrip(categoryCount: state.categories.length, cardCount: state.cardCounts.values.fold(0, (int a, int b) => a + b)),
                  ),

                // ── Content ────────────────────────────────────────────
                if (state.status == CustomCategoryStatus.loading && state.categories.isEmpty)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state.status == CustomCategoryStatus.failure && state.categories.isEmpty)
                  SliverFillRemaining(
                    child: _ErrorState(
                      message: state.errorMessage ?? 'Could not load categories',
                      onRetry: () => context.read<CustomCategoryBloc>().add(const CategoriesLoadRequested()),
                    ),
                  )
                else if (state.categories.isEmpty)
                  SliverFillRemaining(child: _EmptyState(onCreate: () => _openEditor()))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
                    sliver: SliverList.separated(
                      itemCount: state.categories.length,
                      separatorBuilder: (_, int __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (BuildContext ctx, int index) {
                        final CustomCategory cat = state.categories[index];
                        final Color accent = palette[index % palette.length];
                        return _CategoryCard(
                          key: ValueKey<String>('cat_${cat.categoryId}'),
                          category: cat,
                          accent: accent,
                          cardCount: state.cardCounts[cat.categoryId] ?? 0,
                          onTap: () {
                            context.push(AppRoutes.categoryDetail, extra: cat).then((_) {
                              if (context.mounted) {
                                context.read<CustomCategoryBloc>().add(const CategoriesLoadRequested());
                              }
                            });
                          },
                          onEdit: () => _openEditor(editing: cat),
                          onDelete: () => _deleteCategory(cat),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Category'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar background with gradient
// ─────────────────────────────────────────────────────────────────────────────
class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8), theme.colorScheme.surface],
          ),
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Opacity(opacity: 0.06, child: Icon(Icons.folder_special_rounded, size: 140, color: theme.colorScheme.primary)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.85)],
        ),
      ),
      child: const Align(
        alignment: Alignment.topRight,
        child: Opacity(opacity: 0.1, child: Icon(Icons.folder_special_rounded, size: 140, color: Colors.white)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats strip
// ─────────────────────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.categoryCount, required this.cardCount});

  final int categoryCount;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _StatItem(icon: Icons.folder_outlined, label: 'Categories', value: '$categoryCount'),
          Container(width: 1, height: 32, color: theme.colorScheme.outlineVariant),
          _StatItem(icon: Icons.style_outlined, label: 'Total Cards', value: '$cardCount'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, fontSize: 18, color: theme.colorScheme.primary),
            ),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    super.key,
    required this.category,
    required this.accent,
    required this.cardCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomCategory category;
  final Color accent;
  final int cardCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.97, upperBound: 1.0, value: 1.0);
    _scaleAnim = _scaleCtrl.drive(CurveTween(curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.reverse(),
      onTapUp: (_) {
        _scaleCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dismissible(
          key: ValueKey<String>('dismiss_${widget.category.categoryId}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.xxl),
            decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
          ),
          confirmDismiss: (_) async {
            return await _confirmDelete(context, widget.category.name);
          },
          onDismissed: (_) => widget.onDelete(),
          child: Material(
            color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            elevation: isDark ? 0 : 1,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.08),
            child: Stack(
              children: <Widget>[
                // Left accent stripe
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.lg), bottomLeft: Radius.circular(AppRadius.lg)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      // Emoji avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(child: Text(widget.category.iconEmoji, style: const TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Name + card count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    '${widget.cardCount} ${widget.cardCount == 1 ? 'card' : 'cards'}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.accent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: widget.onEdit,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: widget.onTap,
                        tooltip: 'Open',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      final ThemeData theme = Theme.of(ctx);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete Category?'),
        content: Text('"$name" and all its cards will be permanently removed.', style: theme.textTheme.bodyMedium),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
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
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4), shape: BoxShape.circle),
              child: Icon(Icons.folder_special_outlined, size: 52, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'No categories yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Create custom categories for interview questions,\ndebate topics, lesson plans, and more.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Category'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
