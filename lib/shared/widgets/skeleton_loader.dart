import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
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
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[800]!,
                Colors.grey[700]!,
                Colors.grey[800]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class SongCardSkeleton extends StatelessWidget {
  const SongCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 160,
            height: 160,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 12),
          const SkeletonLoader(width: 120, height: 16),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 80, height: 14),
        ],
      ),
    );
  }
}

class AlbumListSkeleton extends StatelessWidget {
  const AlbumListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SkeletonLoader(
        width: 56,
        height: 56,
        borderRadius: BorderRadius.circular(8),
      ),
      title: const SkeletonLoader(width: 150, height: 16),
      subtitle: const SkeletonLoader(width: 100, height: 14),
    );
  }
}