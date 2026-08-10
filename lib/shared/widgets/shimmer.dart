import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A sweeping highlight over placeholder blocks.
///
/// Skeletons that match the shape of what is coming make a load feel shorter
/// than a spinner does, because the layout stops moving the moment real data
/// lands — nothing jumps, it just fills in.
///
/// Hand-rolled rather than a package: it is one AnimationController and a
/// gradient, and it means the sweep uses the same easing as the rest of the app.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            // Travels from fully off one edge to fully off the other, so the
            // highlight never sits parked at the end of its run.
            final double t = _controller.value * 2 - 1;
            return LinearGradient(
              begin: Alignment(t - 0.35, 0),
              end: Alignment(t + 0.35, 0),
              colors: <Color>[
                AppColors.surfaceMuted,
                AppColors.paper2,
                AppColors.surfaceMuted,
              ],
              stops: const <double>[0, 0.5, 1],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A grey block standing in for a line of text or a thumbnail.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// The shape of a lead or listing card, before its data arrives.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 2, this.hasBanner = false});

  final int lines;
  final bool hasBanner;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasBanner) const SkeletonBar(height: 78, radius: 0),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SkeletonBar(width: 170, height: 14),
                const SizedBox(height: 9),
                for (int i = 0; i < lines; i++) ...<Widget>[
                  SkeletonBar(width: i.isEven ? 230 : 140),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: const <Widget>[
                    SkeletonBar(width: 62, height: 22, radius: 11),
                    SizedBox(width: 6),
                    SkeletonBar(width: 84, height: 22, radius: 11),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of skeleton cards — what a surface shows on first load.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.hasBanner = false});

  final int count;
  final bool hasBanner;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => SkeletonCard(hasBanner: hasBanner),
      ),
    );
  }
}
