import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appbar/flutter_appbar.dart';
import 'package:flutter_refresh_indicator/widgets/primary_refresh_indicator.dart';
import 'package:flutter_refresh_indicator/widgets/refresh_indicator_listener.dart';
import 'package:flutter_refresh_indicator/widgets/refresh_indicator_size.dart';

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
  const BouncingRefreshIndicator({
    super.key,
    required this.onRefresh,
    this.displacement = 120,
    this.duration = const Duration(milliseconds: 300),
    this.curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    required this.child,
  });

  /// The callback that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh.
  ///
  /// The returned [Future] must complete when the refresh operation is finished.
  final AsyncCallback onRefresh;

  final double displacement;
  final Duration duration;
  final Curve curve;

  /// The widget to be contained as descendant by this widget.
  final Widget child;

  @override
  State<BouncingRefreshIndicator> createState() =>
      _BouncingRefreshIndicatorState();
}

class _BouncingRefreshIndicatorState extends State<BouncingRefreshIndicator>
    with TickerProviderStateMixin {
  late final AppBarController _appBarController = AppBarController();
  late final AppBarPosition _appbarPosition;

  BouncingRefreshIndicatorStatus status = BouncingRefreshIndicatorStatus.idle;
  bool _isDragging = false;

  NestedScrollPosition? _scrollPosition;

  AnimationController? _animation;
  final Tween<double> _tween = Tween(begin: 0, end: 0);

  double get distancePixels {
    return _tween.transform(widget.curve.transform(_animation?.value ?? 0));
  }

  double get distanceFraction {
    return (-distancePixels / widget.displacement).clamp(0, 1);
  }

  void moveTo(double newValue) {
    setState(() {
      _animation?.dispose();
      _animation = null;
      _tween.begin = newValue;
      _tween.end = newValue;
    });
  }

  void animateTo(double newValue) {
    _tween.begin = distancePixels;
    _tween.end = newValue;
    _animation?.dispose();
    _animation = AnimationController(vsync: this, duration: widget.duration);
    _animation!.addListener(() => setState(() {}));
    _animation!.forward();
  }

  void fadeout() {
    animateTo(0);
    status = BouncingRefreshIndicatorStatus.loaded;

    _animation!.addStatusListener((animStatus) {
      if (animStatus != AnimationStatus.completed) return;
      status = BouncingRefreshIndicatorStatus.idle;
      _appbarPosition.setPixels(0);
    });
  }

  double _handleNestedScroll(double available, NestedScrollPosition scroll) {
    if (status == BouncingRefreshIndicatorStatus.loading) {
      return _appBarController.consumeScroll(
        available,
        scroll,
        AppbarPropagation.next,
      );
    }

    return 0.0;
  }

  AppBarPosition createAppBarPosition() {
    return AppBarPosition(
      vsync: this,
      behavior: MaterialAppBarBehavior(alwaysScrolling: false),
    );
  }

  @override
  void initState() {
    super.initState();
    _appBarController.attach(_appbarPosition = createAppBarPosition());
  }

  @override
  void dispose() {
    _appBarController.dispose();
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = PrimaryRefreshIndicator.maybeOf(context);

    // The builder used to create the refresh indicator widget.
    final indicatorBuilder =
        primary?.bouncingIndicatorBuilder ?? _defaultIndicatorBuilder;

    return RefreshIndicatorListener(
      onPointerCancel: (event) => _isDragging = false,
      onPointerDown: (event) => _isDragging = true,
      onPointerUp: (event) {
        _isDragging = false;

        if (distanceFraction == 1.0) {
          _scrollPosition?.goIdle();
          _scrollPosition?.lentPixels = 0.0;

          status = BouncingRefreshIndicatorStatus.loading;
          animateTo(-_appbarPosition.maxExtent);
          widget.onRefresh().then((value) => fadeout());
        }
      },
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _appbarPosition,
            builder: (context, child) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(),
                height: distancePixels.abs(),
                child: Transform.translate(
                  offset: Offset(0, -_appbarPosition.pixels),
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: _appbarPosition.maxExtent,
                    maxWidth: _appbarPosition.maxExtent,
                    minHeight: _appbarPosition.maxExtent,
                    maxHeight: double.infinity,
                    child: Builder(
                      builder: (context) {
                        final bool isActivable;
                        final bool isActive =
                            status != BouncingRefreshIndicatorStatus.idle;

                        if (isActive) {
                          isActivable = true;
                        } else {
                          isActivable = _isDragging && distanceFraction == 1.0;
                        }

                        return RefreshIndicatorSize(
                          onSize: (newSize) {
                            setState(() {
                              _appbarPosition.maxExtent = newSize.height;
                            });
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
            animation: _appbarPosition,
            builder: (context, child) {
              final Offset appbar = Offset(0, _appbarPosition.expandedPercent);
              final Offset offset = Offset(0, -distancePixels * appbar.dy);

              return Transform.translate(
                transformHitTests: false,
                offset: offset,
                child: NestedScrollConnection(
                  onPreScroll: _handleNestedScroll,
                  onPostScroll: _handleNestedScroll,
                  onBouncing: (available, position) {
                    _scrollPosition = position;

                    if (status == BouncingRefreshIndicatorStatus.idle) {
                      final double prvValue = distancePixels;
                      final double newValue = (prvValue + available).clamp(
                        -double.infinity,
                        0,
                      );
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
      padding: EdgeInsets.symmetric(vertical: 15),
      child: Opacity(
        opacity: isActive ? 1.0 : fraction,
        child: Builder(
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
    );
  }
}
