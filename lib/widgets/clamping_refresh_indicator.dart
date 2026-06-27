import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appbar/flutter_appbar.dart';
import 'package:flutter_refresh_indicator/flutter_refresh_indicator.dart';
import 'package:flutter_refresh_indicator/widgets/refresh_indicator_listener.dart';

/// Signature for a builder function that creates a widget for a
/// [ClampingRefreshIndicator] based on the current refresh status.
typedef ClampingRefreshIndicatorBuilder = Widget Function(
  ClampingRefreshIndicatorStatus status,
  double fraction,
  double fadeFraction,
  bool isActivable,
);

/// Signature for the current status of a [ClampingRefreshIndicator].
/// Indicates whether the indicator is idle, being pulled, or loading.
enum ClampingRefreshIndicatorStatus { idle, pulling, loading }

class ClampingRefreshIndicator extends StatefulWidget {
  const ClampingRefreshIndicator({
    super.key,
    required this.onRefresh,
    this.indicatorBuilder,
    this.maxDragDistance = 250,
    this.displacement = 150,
    this.displacementPercent = 0.5,
    this.edgeOffset = 0.0,
    this.duration = const Duration(milliseconds: 200),
    this.curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    this.fadeDuration = const Duration(milliseconds: 150),
    this.fadeCurve = Curves.easeOutQuad,
    this.enabled = true,
    required this.child,
  });

  /// The callback that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh.
  ///
  /// The returned [Future] must complete when the refresh operation is finished.
  final AsyncCallback onRefresh;

  final ClampingRefreshIndicatorBuilder? indicatorBuilder;
  final double maxDragDistance;
  final double displacement;
  final double displacementPercent;
  final double edgeOffset;
  final Duration duration;
  final Curve curve;
  final Duration fadeDuration;
  final Curve fadeCurve;

  /// Whether users can pull to trigger the refresh operation.
  final bool enabled;

  /// The widget to be contained as descendant by this widget.
  final Widget child;

  @override
  State<ClampingRefreshIndicator> createState() => _ClampingRefreshIndicatorState();
}

class _ClampingRefreshIndicatorState extends State<ClampingRefreshIndicator> with TickerProviderStateMixin {
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

  /// Triggers a widget rebuild by calling [setState] if the widget is currently mounted.
  void _didUpdateState() {
    if (mounted) setState(() {});
  }

  /// Instantly moves the indicator to [newValue] by stopping
  /// any active pulling animation and resetting the tween range.
  void _moveTo(double newValue) {
    setState(() {
      _pullingAnimation?.dispose();
      _pullingAnimation = null;
      _pullingTween.begin = newValue;
      _pullingTween.end = newValue;
    });
  }

  /// Animates the indicator from its current fraction
  /// to [newValue] using a new [AnimationController].
  void _animateTo(double newValue) {
    _pullingTween.begin = distanceFraction;
    _pullingTween.end = newValue;

    _pullingAnimation?.dispose();
    _pullingAnimation = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _pullingAnimation!.addListener(_didUpdateState);
    _pullingAnimation!.forward();
  }

  /// Starts the fade-out animation and resets the status
  /// to idle once the animation completes.
  void _animateFadeOut() {
    _fadeoutAniamtion?.dispose();
    _fadeoutAniamtion = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeoutAniamtion!.addListener(_didUpdateState);
    _fadeoutAniamtion!.addStatusListener((animStatus) {
      if (animStatus == AnimationStatus.completed) {
        status = ClampingRefreshIndicatorStatus.idle;
        _fadeoutAniamtion = null;
        _moveTo(0.0);
      }
    });
    _fadeoutAniamtion!.forward();
  }

  /// Initiates the fade-out process, waiting for the active pulling
  /// animation to finish first if it is currently running.
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

  /// Handles nested scroll events to update the pull distance
  /// and transition the status to pulling when appropriate.
  double _handleNestedScroll(double available, ScrollPosition position) {
    // If the indicator is disabled, loading, not at the top,
    // or not being dragged, ignore the scroll event.
    if (status == ClampingRefreshIndicatorStatus.loading || position.pixels != 0.0 || !_isDragging) {
      return 0.0;
    }

    // Update the status to pulling if the user is actively dragging downward.
    if (_isDragging && position.userScrollDirection == ScrollDirection.forward) {
      status = ClampingRefreshIndicatorStatus.pulling;
    }

    // Calculate the new drag fraction based on the available scroll delta.
    final double factor = widget.maxDragDistance;
    final double newValue = (distanceFraction + (available / factor)).clamp(0.0, 1.0);
    setState(() => _moveTo(newValue));

    return newValue == 0.0 ? 0.0 : available;
  }

  double _handleNestedFling(double available, ScrollPosition position) {
    return status == ClampingRefreshIndicatorStatus.pulling ? available : 0.0;
  }

  /// Called when the user ends the drag, Starts loading
  /// if pulled enough, otherwise resets and snaps back.
  void onPointerEnd(double fraction, PointerEvent event) {
    if (fraction >= widget.displacementPercent) {
      Future.microtask(() => status = ClampingRefreshIndicatorStatus.loading);
      _moveTo(fraction);
      _animateTo(widget.displacementPercent);

      widget.onRefresh().then((value) => _fadeOut());
    } else if (status != ClampingRefreshIndicatorStatus.idle) {
      status = ClampingRefreshIndicatorStatus.idle;
      _moveTo(fraction);
      _animateTo(0.0);
    }

    _isDragging = false;
  }

  /// Called when the user starts the drag.
  void onPointerDown(PointerDownEvent event) {
    if (widget.enabled) _isDragging = true;
  }

  @override
  Widget build(BuildContext context) {
    final primary = PrimaryRefreshIndicator.maybeOf(context);

    // The builder used to create the refresh indicator widget.
    final indicatorBuilder = primary?.clampingIndicatorBuilder ?? _defaultIndicatorBuilder;

    // Calculate the fraction for the indicator animation.
    // Uses an easeOut curve if currently pulling,
    // otherwise uses the raw distance fraction.
    final fraction = status == ClampingRefreshIndicatorStatus.pulling
        ? Curves.easeOut.transform(distanceFraction)
        : distanceFraction;

    // Whether the indicator is currently activable.
    final isActivable = distanceFraction >= widget.displacementPercent;

    return RefreshIndicatorListener(
      onPointerDown: onPointerDown,
      onPointerUp: (event) => onPointerEnd(fraction, event),
      onPointerCancel: (event) => onPointerEnd(fraction, event),
      child: ClipRRect(
        child: Stack(
          children: [
            NestedScrollConnection(
              propagation: NestedScrollConnectionPropagation.deferToAncestor,
              predicate: (available, position) {
                final bool isPulling = available < 0 && status == ClampingRefreshIndicatorStatus.pulling;

                return isPulling && distanceFraction != 0;
              },
              onPreScroll: _handleNestedScroll,
              onFling: _handleNestedFling,
              child: NestedScrollControllerScope(
                factory: (context) => NestedScrollController(),
                builder: (context, _) => widget.child,
              ),
            ),
            if (fraction != 0.0)
              Positioned.fill(
                top: (widget.displacement * fraction) + widget.edgeOffset,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FractionalTranslation(
                      translation: Offset(0, -1),
                      child: indicatorBuilder(
                        status,
                        fraction,
                        fadeFraction,
                        isActivable,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The default builder for a clamping-style refresh indicator.
  /// Displays a [RefreshProgressIndicator] that scales and fades
  /// based on the current pull progress.
  static Widget _defaultIndicatorBuilder(
    ClampingRefreshIndicatorStatus status,
    double fraction,
    double fadeFraction,
    bool isActivable,
  ) {
    return Transform.scale(
      scale: fadeFraction,
      child: Opacity(
        opacity: fadeFraction,
        child: RefreshProgressIndicator(
          value: status == ClampingRefreshIndicatorStatus.pulling ? fraction * 0.8 : null,
        ),
      ),
    );
  }
}
