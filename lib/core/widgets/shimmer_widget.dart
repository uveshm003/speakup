import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_radius.dart';

/// Animated shimmer placeholder. Uses [AnimatedOpacity] alternating between
/// two surface tones — no external packages required.
class ShimmerWidget extends StatefulWidget {
  const ShimmerWidget({super.key, required this.width, required this.height, this.borderRadius});

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.75).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: _opacity.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.md),
          ),
        );
      },
    );
  }
}

/// A column of shimmer rectangles that mimics a card list skeleton.
class ShimmerListPlaceholder extends StatelessWidget {
  const ShimmerListPlaceholder({super.key, this.itemCount = 5, this.itemHeight = 72});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, int i) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, _) =>
          ShimmerWidget(width: double.infinity, height: itemHeight, borderRadius: BorderRadius.circular(AppRadius.lg)),
    );
  }
}

/// 2-column shimmer grid for Favorites loading.
class ShimmerGridPlaceholder extends StatelessWidget {
  const ShimmerGridPlaceholder({super.key, this.crossAxisCount = 2, this.itemCount = 6});

  final int crossAxisCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, _) =>
          ShimmerWidget(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(AppRadius.lg)),
    );
  }
}
