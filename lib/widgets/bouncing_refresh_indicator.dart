import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:flutter_appbar/flutter_appbar.dart';
import 'package:flutter_refresh_indicator/widgets/global_listener.dart';
import 'package:flutter_refresh_indicator/widgets/primary_refresh_indicator.dart';

enum BouncingRefreshIndicatorStatus {
  idle,
  loading,
  loaded
}

class BouncingRefreshIndicator extends StatefulWidget {
  const BouncingRefreshIndicator({
    super.key,
    required this.onRefresh,
    this.foregroundColor,
    this.backgroundColor,
    this.displacement = 150,
    this.displacementPercent = 0.5,
    this.duration = const Duration(milliseconds: 300),
    this.curve = const Cubic(0.4, 0.0, 0.2, 1.0),
    this.fadeDuration = const Duration(milliseconds: 300),
    this.fadeCurve = Curves.ease,
    required this.child
  });

  final AsyncCallback onRefresh;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double displacement;
  final double displacementPercent;
  final Duration duration;
  final Curve curve;
  final Duration fadeDuration;
  final Curve fadeCurve;
  final Widget child;

  @override
  State<BouncingRefreshIndicator> createState() => _BouncingRefreshIndicatorState();
}

class _BouncingRefreshIndicatorState extends State<BouncingRefreshIndicator> with TickerProviderStateMixin {
  BouncingRefreshIndicatorStatus status = BouncingRefreshIndicatorStatus.idle;
  bool _isDragging = false;

  NestedScrollPosition? _cacehdScrollPosition;

  late final AppBarController _appBarController = AppBarController();
  late final AppBarPosition _appbarPosition;

  AnimationController? _animation;
  final Tween<double> _tween = Tween(begin: 0, end: 0);

  static double get areaHeight => 50;

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

  double _handleNestedScroll(double available, ScrollPosition scroll) {
    if (status == BouncingRefreshIndicatorStatus.loading) {
      return _appBarController.consumeScroll(available, scroll, AppbarPropagation.next);
    }

    return 0.0;
  }

  AppBarPosition createAppBarPosition() {
    return AppBarPosition(
      vsync: this,
      behavior: MaterialAppBarBehavior(alwaysScrolling: false)
    )..maxExtent = areaHeight;
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
    final PrimaryRefreshIndicator? primary = PrimaryRefreshIndicator.maybeOf(context);
    final Color? foregroundColor = widget.foregroundColor ?? primary?.bouncing?.foregroundColor;
    final Color? backgroundColor = widget.backgroundColor ?? primary?.bouncing?.backgroundColor;

    return GlobalListener(
      onPointerCancel: (event) => _isDragging = false,
      onPointerDown: (event) => _isDragging = true,
      onPointerUp: (event) {
        _isDragging = false;

        if ( distanceFraction > widget.displacementPercent) {
          _cacehdScrollPosition?.goIdle();
          _cacehdScrollPosition?.lentPixels = 0.0;

          status = BouncingRefreshIndicatorStatus.loading;
          animateTo(-areaHeight);
          widget.onRefresh().then((value) => fadeout());
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _appbarPosition,
              builder: (context, child) {
                return ClipRRect(
                  child: Transform.translate(
                    offset: Offset(0, -_appbarPosition.pixels),
                    child: Container(
                      height: areaHeight,
                      alignment: Alignment.topCenter,
                      child: Builder(
                        builder: (context) {
                          final bool isActivable;
                          final bool isActive = status != BouncingRefreshIndicatorStatus.idle;

                          if (isActive) {
                            isActivable = true;
                          } else {
                            isActivable = _isDragging && distanceFraction > widget.displacementPercent;
                          }

                          return AnimatedOpacity(
                            opacity: isActivable ? 1.0 : 0.5,
                            duration: widget.fadeDuration,
                            curve: widget.curve,
                            child: RefreshProgressIndicator(
                              color: foregroundColor,
                              backgroundColor: backgroundColor ?? Colors.transparent,
                              value: isActive ? null : 0.8 * distanceFraction,
                              elevation: 0,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
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
                    assert(
                      position is NestedScrollPosition,
                      "The ScrollController of a Scrollable widget must always be defined as a NestedScrollController."
                    );
                    _cacehdScrollPosition = position as NestedScrollPosition;

                    if (status == BouncingRefreshIndicatorStatus.idle) {
                      final double prvValue = distancePixels;
                      final double newValue = (prvValue + available).clamp(-double.infinity, 0);
                      moveTo(newValue);
                      return newValue - prvValue;
                    }

                    return 0.0;
                  },
                  child: widget.child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}