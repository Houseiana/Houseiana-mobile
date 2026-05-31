import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced animations for better user experience
class EnhancedAnimations {
  EnhancedAnimations._();

  // Duration constants
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);

  // Curve constants
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}

/// Scale animation on tap
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double scaleValue;
  final Duration duration;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.scaleValue = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleValue : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

/// Bounce animation on tap
class BounceOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double bounceValue;

  const BounceOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.bounceValue = 0.9,
  });

  @override
  State<BounceOnTap> createState() => _BounceOnTapState();
}

class _BounceOnTapState extends State<BounceOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: widget.bounceValue), weight: 50),
      TweenSequenceItem(tween: Tween(begin: widget.bounceValue, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _controller.forward(from: 0);
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Heart beat animation (for favorites)
class HeartBeatAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;

  const HeartBeatAnimation({
    super.key,
    required this.child,
    this.animate = false,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<HeartBeatAnimation> createState() => _HeartBeatAnimationState();
}

class _HeartBeatAnimationState extends State<HeartBeatAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(HeartBeatAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    }
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
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Staggered list animation wrapper
class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration animationDuration;
  final double offset;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
    this.offset = 20.0,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after delay based on index
    Future.delayed(
      Duration(milliseconds: widget.baseDelay.inMilliseconds * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Pull to refresh indicator animation
class RefreshIndicatorAnimation extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? indicator;

  const RefreshIndicatorAnimation({
    super.key,
    required this.child,
    required this.onRefresh,
    this.indicator,
  });

  @override
  State<RefreshIndicatorAnimation> createState() =>
      _RefreshIndicatorAnimationState();
}

class _RefreshIndicatorAnimationState
    extends State<RefreshIndicatorAnimation> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: const Color(0xFFFCC519),
      backgroundColor: Colors.white,
      displacement: 50,
      strokeWidth: 2,
      child: widget.child,
    );
  }
}

/// Loading shimmer effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE8E8E8),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.enabled = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: widget.child,
        );
      },
    );
  }
}
