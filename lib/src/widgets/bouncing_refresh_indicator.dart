import 'dart:math';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_nested_scroll/flutter_nested_scroll.dart';
import 'package:flutter_refresh_indicator/src/widgets/primary_refresh_indicator.dart';
import 'package:flutter_refresh_indicator/src/widgets/global_pointer_listener.dart';
import 'package:flutter_refresh_indicator/src/widgets/size_reporter.dart';

/// Signature for a builder function that creates a widget for a
/// [BouncingRefreshIndicator] based on the current refresh status.
typedef BouncingRefreshIndicatorBuilder = Widget Function(
  BouncingRefreshIndicatorStatus status,
  double fraction,
  bool isActive,
  bool isActivable,
);

/// Signature for the current status of a [BouncingRefreshIndicator].
/// Indicates whether the indicator is idle, loading, or loaded.
enum BouncingRefreshIndicatorStatus { idle, loading, loaded }

class BouncingRefreshIndicator extends StatefulWidget {
  const new({
    super.key,
    required this.onRefresh,
    this.displacement = 120,
    this.physics,
    this.enabled = true,
    required this.child,
  });

  /// The callback that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh.
  ///
  /// The returned [Future] must complete when the refresh operation is finished.
  final AsyncCallback onRefresh;

  /// The minimum drag distance required to trigger the [onRefresh] callback.
  final double displacement;

  /// The scroll physics that determine the spring behavior
  /// when pulling or releasing the indicator for refresh.
  final ScrollPhysics? physics;

  /// Whether users can pull to trigger the refresh operation.
  final bool enabled;

  /// The widget to be contained as descendant by this widget.
  final Widget child;

  @override
  State<BouncingRefreshIndicator> createState() => _BouncingRefreshIndicatorState();
}

class _BouncingRefreshIndicatorState extends State<BouncingRefreshIndicator> with TickerProviderStateMixin {
  /// The collapsed fraction of the indicator while refreshing.
  final _collapseFraction = ValueNotifier<double>(0.0);
  double _indicatorExtent = 0.0;

  double get _indicatorPixels => _indicatorExtent * _collapseFraction.value;

  BouncingRefreshIndicatorStatus status = .idle;
  bool _isDragging = false;

  NestedScrollPosition? _scrollPosition;
  AnimationController? _animation;
  double _distancePixels = 0.0;

  ScrollPhysics get physics {
    return widget.physics ?? _scrollPosition?.physics ?? const BouncingScrollPhysics();
  }

  double get distancePixels {
    return _animation?.value ?? _distancePixels;
  }

  double get distanceFraction {
    return (-distancePixels / widget.displacement).clamp(0, 1);
  }

  double get _defaultViewportDimension => MediaQuery.of(context).size.height;
  double get _defaultDevicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  /// Disposes of the active animation controller and clears its reference.
  void _disposeAnimation() {
    _animation?.dispose();
    _animation = null;
  }

  /// Triggers a widget rebuild by calling [setState] if the widget is currently mounted.
  void _didUpdateState() {
    if (mounted) setState(() {});
  }

  /// Instantly moves to the [newValue] position by canceling
  /// any active animation and updating the distance state.
  void moveTo(double newValue) {
    setState(() {
      _disposeAnimation();
      _distancePixels = newValue;
    });
  }

  /// Animates the distance to [newValue] using a physics-based
  /// simulation(spring) and returns the [AnimationController].
  AnimationController? animateTo(double newValue) {
    final double oldValue = distancePixels;
    const double velocity = 0.0;

    if (oldValue == newValue) {
      moveTo(newValue);
      return null;
    }

    final ScrollMetrics metrics = FixedScrollMetrics(
      minScrollExtent: newValue,
      maxScrollExtent: newValue,
      pixels: oldValue,
      viewportDimension: _scrollPosition?.viewportDimension ?? _defaultViewportDimension,
      devicePixelRatio: _scrollPosition?.devicePixelRatio ?? _defaultDevicePixelRatio,
      axisDirection: _scrollPosition?.axisDirection ?? .down,
    );

    Simulation? simulation = physics.createBallisticSimulation(metrics, velocity);

    simulation ??= ScrollSpringSimulation(
      physics.spring,
      oldValue,
      newValue,
      velocity,
      tolerance: physics.toleranceFor(metrics),
    );

    _disposeAnimation();
    final controller = AnimationController.unbounded(value: oldValue, vsync: this);

    _animation = controller;
    controller.addListener(_didUpdateState);
    controller.addStatusListener((status) {
      if (status == .completed) {
        _distancePixels = newValue;
        _animation = null;
        _didUpdateState();
        Future.microtask(controller.dispose);
      }
    });

    return controller..animateWith(simulation);
  }

  /// Fades out the indicator by animating back to 0,
  /// resetting the status and collapsed fraction upon completion.
  void fadeout() {
    final animation = animateTo(0);
    status = .loaded;

    void complete() {
      status = .idle;
      _collapseFraction.value = 0;
    }

    if (animation == null) {
      return complete();
    }

    animation.addStatusListener((status) {
      if (status == .completed) complete();
    });
  }

  /// Collapses or expands the loading indicator before passing remaining
  /// scroll distance to the content, matching the previous app bar behavior.
  double _handleNestedScroll(double available, NestedScrollPosition scroll) {
    if (status != .loading || _indicatorExtent == 0.0) {
      return 0.0;
    }

    // Only consume normal scrolling at the leading edge of scrollable content.
    if (scroll.totalPixels < scroll.minScrollExtent || scroll.totalPixels > scroll.maxScrollExtent) {
      return 0.0;
    }

    if (scroll.pixels > precisionErrorTolerance) {
      return 0.0;
    }

    if (_indicatorExtent > scroll.maxScrollExtent + _indicatorPixels) {
      return 0.0;
    }

    final oldPixels = _indicatorPixels;
    _collapseFraction.value = ((oldPixels - available) / _indicatorExtent).clamp(0.0, 1.0);
    final consumed = oldPixels - _indicatorPixels;

    // The translated content changes the scroll range by the consumed distance.
    if (consumed.abs() > precisionErrorTolerance) {
      scroll.applyContentDimensions(
        scroll.minScrollExtent,
        max(
          scroll.minScrollExtent,
          scroll.maxScrollExtent + consumed,
        ),
      );
    }

    return consumed;
  }

  @override
  void dispose() {
    _collapseFraction.dispose();
    _disposeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = PrimaryRefreshIndicator.maybeOf(context);

    // The builder used to create the refresh indicator widget.
    final indicatorBuilder = primary?.bouncingIndicatorBuilder ?? _defaultIndicatorBuilder;

    return GlobalPointerListener(
      onPointerCancel: (event) => _isDragging = false,
      onPointerDown: (event) => _isDragging = true,
      onPointerUp: (event) {
        _isDragging = false;

        if (distanceFraction == 1.0) {
          _scrollPosition?.goIdle();
          _scrollPosition?.lentPixels = 0.0;

          status = .loading;
          animateTo(-_indicatorExtent);
          widget.onRefresh().then((value) => fadeout());
        }
      },
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _collapseFraction,
            builder: (context, child) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(),
                height: distancePixels.abs(),
                child: Transform.translate(
                  offset: Offset(0, -_indicatorPixels),
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: _indicatorExtent,
                    maxWidth: _indicatorExtent,
                    minHeight: _indicatorExtent,
                    maxHeight: double.infinity,
                    child: Builder(
                      builder: (context) {
                        final bool isActivable;
                        final bool isActive = status != .idle;

                        if (isActive) {
                          isActivable = true;
                        } else {
                          isActivable = _isDragging && distanceFraction == 1.0;
                        }

                        return SizeReporter(
                          onSize: (newSize) {
                            setState(() => _indicatorExtent = newSize.height);
                          },
                          child: indicatorBuilder(
                            status,
                            distanceFraction,
                            isActive,
                            isActivable,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _collapseFraction,
            builder: (context, child) {
              final Offset offset = Offset(0, -distancePixels * (1 - _collapseFraction.value));

              return Transform.translate(
                transformHitTests: false,
                offset: offset,
                child: NestedScrollConnection(
                  onPreScroll: _handleNestedScroll,
                  onPostScroll: _handleNestedScroll,
                  onBouncing: (available, position) {
                    _scrollPosition = position;

                    if (widget.enabled && status == BouncingRefreshIndicatorStatus.idle) {
                      final double prvValue = distancePixels;
                      final double newValue = (prvValue + available).clamp(-double.infinity, 0);
                      moveTo(newValue);
                      return newValue - prvValue;
                    }

                    return 0.0;
                  },
                  child: NestedScrollControllerScope(
                    factory: (context) => NestedScrollController(),
                    builder: (context, _) => widget.child,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// The default builder for a bouncing-style refresh indicator.
  /// Displays a [CupertinoActivityIndicator] that fades and
  /// updates its visibility based on the pull progress.
  static Widget _defaultIndicatorBuilder(
    BouncingRefreshIndicatorStatus status,
    double fraction,
    bool isActive,
    bool isActivable,
  ) {
    return Padding(
      padding: .symmetric(vertical: 15),
      child: Opacity(
        opacity: isActive ? 1.0 : fraction,
        child: AnimatedSwitcher(
          duration: .new(milliseconds: 300),
          child: Builder(
            key: ValueKey(isActivable),
            builder: (context) {
              if (isActivable) {
                return CupertinoActivityIndicator(radius: 15);
              }

              return CupertinoActivityIndicator.partiallyRevealed(
                progress: fraction,
                radius: 15,
              );
            },
          ),
        ),
      ),
    );
  }
}
