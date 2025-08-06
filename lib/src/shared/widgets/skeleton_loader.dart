import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor =
        widget.baseColor ??
        (isDark
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5));

    final highlightColor =
        widget.highlightColor ??
        (isDark
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : theme.colorScheme.surfaceContainer.withValues(alpha: 0.8));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ??
                BorderRadius.circular(AppSpacing.radiusSm),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, 0.5 + _animation.value * 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final List<Widget> children;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.margin,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            isDark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.2,
                ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final int lines;
  final double spacing;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
    this.lines = 1,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        final lineWidth =
            isLast && lines > 1
                ? (width ?? double.infinity) * 0.7
                : width ?? double.infinity;

        return Column(
          children: [
            SkeletonLoader(width: lineWidth, height: height),
            if (!isLast) SizedBox(height: spacing),
          ],
        );
      }),
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double size;
  final bool isCircle;

  const SkeletonAvatar({super.key, this.size = 40, this.isCircle = true});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius:
          isCircle
              ? BorderRadius.circular(size / 2)
              : BorderRadius.circular(AppSpacing.radiusSm),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final bool hasSubtitle;

  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = true,
    this.hasSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      children: [
        Row(
          children: [
            if (hasLeading) ...[
              const SkeletonAvatar(size: 40),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(height: 18),
                  if (hasSubtitle) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SkeletonText(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.6,
                    ),
                  ],
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: AppSpacing.md),
              const SkeletonText(width: 60, height: 16),
            ],
          ],
        ),
      ],
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;
  final int crossAxisCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const SkeletonGrid({
    super.key,
    required this.itemCount,
    this.childAspectRatio = 1.0,
    this.crossAxisCount = 2,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class SkeletonChart extends StatelessWidget {
  final double height;
  final double width;

  const SkeletonChart({
    super.key,
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: width,
      height: height,
      children: [
        const SkeletonText(width: 120, height: 20),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final heights = [60.0, 80.0, 40.0, 100.0, 70.0, 90.0, 50.0];
              return SkeletonLoader(
                width: 20,
                height: heights[index],
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              );
            }),
          ),
        ),
      ],
    );
  }
}
