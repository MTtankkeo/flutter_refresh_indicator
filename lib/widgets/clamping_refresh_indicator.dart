import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_appbar/flutter_appbar.dart';
import 'package:flutter_refresh_indicator/flutter_refresh_indicator.dart';
import 'package:flutter_refresh_indicator/widgets/global_listener.dart';

enum ClampingRefreshIndicatorStatus { idle, pulling, loading }

class ClampingRefreshIndicator extends StatefulWidget {
  const ClampingRefreshIndicator({
    super.key,
    required this.onRefresh,
    this.foregroundColor,
    this.backgroundColor,
    this.maxDragDistance = 250,
    this.displacement = 150,
    this.displacementPercent = 0.5,
    this.edgeOffset = 0.0,
    this.duration = const Duration(milliseconds: 200),
    this.curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    this.fadeDuration = const Duration(milliseconds: 150),
    this.fadeCurve = Curves.easeOutQuad,
    required this.child,
  });

  /// The callback that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh.
  ///
  /// The returned [Future] must complete when the refresh operation is finished.
  final AsyncCallback onRefresh;

  final Color? foregroundColor;
  final Color? backgroundColor;
  final double maxDragDistance;
  final double displacement;
  final double displacementPercent;
  final double edgeOffset;
  final Duration duration;
  final Curve curve;
  final Duration fadeDuration;
  final Curve fadeCurve;

  /// The widget to be contained as descendant by this widget.
  final Widget child;

  @override
  State<ClampingRefreshIndicator> createState() =>
      _ClampingRefreshIndicatorState();
}

class _ClampingRefreshIndicatorState extends State<ClampingRefreshIndicator>
    with TickerProviderStateMixin {
  ClampingRefreshIndicatorStatus status = ClampingRefreshIndicatorStatus.idle;
  bool _isDragging = false;

  bool get isRefreshing => status == ClampingRefreshIndicatorStatus.loading;

  AnimationController? _fadeoutAniamtion;
  AnimationController? _pullingAnimation;
  final Tween<double> _pullingTween = Tween(begin: 0, end: 0);

  double get distanceFraction {
    return _pullingTween.transform(
      widget.curve.transform(_pullingAnimation?.value ?? 1),
    );
  }

  double get fadeFraction {
    return 1 - (widget.fadeCurve.transform(_fadeoutAniamtion?.value ?? 0));
  }

  void _moveTo(double newValue) {
    setState(() {
      _pullingAnimation?.dispose();
      _pullingAnimation = null;
      _pullingTween.begin = newValue;
      _pullingTween.end = newValue;
    });
  }

  void _animateTo(double newValue) {
    _pullingTween.begin = distanceFraction;
    _pullingTween.end = newValue;

    _pullingAnimation?.dispose();
    _pullingAnimation = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _pullingAnimation!.addListener(() => setState(() {}));
    _pullingAnimation!.forward();
  }

  void _animateFadeOut() {
    _fadeoutAniamtion?.dispose();
    _fadeoutAniamtion = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeoutAniamtion!.addListener(() => setState(() => {}));
    _fadeoutAniamtion!.addStatusListener((animStatus) {
      if (animStatus == AnimationStatus.completed) {
        status = ClampingRefreshIndicatorStatus.idle;
        _fadeoutAniamtion = null;
        _moveTo(0.0);
      }
    });
    _fadeoutAniamtion!.forward();
  }

  void _fadeOut() {
    if (_pullingAnimation?.isAnimating ?? false) {
      // Waits until the pull animation is finished if it's currently running.
      _pullingAnimation?.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animateFadeOut();
        }
      });
    } else {
      _animateFadeOut();
    }
  }

  @override
  void dispose() {
    _pullingAnimation?.dispose();
    _fadeoutAniamtion?.dispose();
    super.dispose();
  }

  double _handleNestedScroll(double available, ScrollPosition position) {
    if (status == ClampingRefreshIndicatorStatus.loading ||
        position.pixels != 0.0 ||
        !_isDragging) {
      return 0.0;
    }

    if (_isDragging &&
        position.userScrollDirection == ScrollDirection.forward) {
      status = ClampingRefreshIndicatorStatus.pulling;
    }

    final double factor = widget.maxDragDistance;
    final double newValue = (distanceFraction + (available / factor)).clamp(
      0.0,
      1.0,
    );
    setState(() => _moveTo(newValue));

    return newValue == 0.0 ? 0.0 : available;
  }

  double _handleNestedFling(double available, ScrollPosition position) {
    return status == ClampingRefreshIndicatorStatus.pulling ? available : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final PrimaryRefreshIndicator? primary = PrimaryRefreshIndicator.maybeOf(
      context,
    );
    final Color? foregroundColor =
        widget.foregroundColor ?? primary?.clamping?.foregroundColor;
    final Color? backgroundColor =
        widget.backgroundColor ?? primary?.clamping?.backgroundColor;

    final fraction =
        status == ClampingRefreshIndicatorStatus.pulling
            ? Curves.easeOut.transform(distanceFraction)
            : distanceFraction;

    return GlobalListener(
      onPointerCancel: (event) => _isDragging = false,
      onPointerDown: (event) => _isDragging = true,
      onPointerUp: (event) {
        if (fraction >= widget.displacementPercent) {
          Future.microtask(
            () => status = ClampingRefreshIndicatorStatus.loading,
          );
          _moveTo(fraction);
          _animateTo(widget.displacementPercent);

          widget.onRefresh().then((value) => _fadeOut());
        } else {
          status = ClampingRefreshIndicatorStatus.idle;
          _moveTo(fraction);
          _animateTo(0.0);
        }

        _isDragging = false;
      },
      child: ClipRRect(
        child: Stack(
          children: [
            PrimaryScrollController(
              controller: NestedScrollController(),
              scrollDirection: Axis.vertical,
              child: NestedScrollConnection(
                propagation:
                    distanceFraction == 0
                        ? NestedScrollConnectionPropagation.deferToAncestor
                        : NestedScrollConnectionPropagation.selfFirst,
                onPreScroll: _handleNestedScroll,
                onFling: _handleNestedFling,
                child: widget.child,
              ),
            ),

            if (fraction != 0.0)
              Positioned.fill(
                top: (widget.displacement * fraction) + widget.edgeOffset,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _ProgressIndicator(
                      fraction: fraction,
                      fadeFraction: fadeFraction,
                      status: status,
                      foregroundColor: foregroundColor,
                      backgroundColor: backgroundColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.fraction,
    required this.fadeFraction,
    required this.status,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final double fraction;
  final double fadeFraction;
  final ClampingRefreshIndicatorStatus status;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: Offset(0, -1),
      child: Transform.scale(
        scale: fadeFraction,
        child: Opacity(
          opacity: fadeFraction,
          child: RefreshProgressIndicator(
            value:
                status == ClampingRefreshIndicatorStatus.pulling
                    ? fraction * 0.8
                    : null,
            color: foregroundColor,
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );
  }
}
