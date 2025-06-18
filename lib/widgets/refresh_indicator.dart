import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_refresh_indicator/flutter_refresh_indicator.dart';

enum RefreshIndicatorType { clamping, bouncing }

/// Signature for the alias that is representing of the [RefreshIndicator] widget.
typedef PullToRefresh = RefreshIndicator;

/// Signature for the alias that is representing of the [RefreshIndicator] widget.
typedef SwipeToRefresh = RefreshIndicator;

/// A widget that supports the Material "swipe to refresh" idiom.
class RefreshIndicator extends StatefulWidget {
  const RefreshIndicator({
    super.key,
    this.type,
    required this.onRefresh,
    required this.child,
  });

  final RefreshIndicatorType? type;

  /// The callback that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh.
  ///
  /// The returned [Future] must complete when the refresh operation is finished.
  final AsyncCallback onRefresh;

  /// The widget to be contained as descendant by this widget.
  final Widget child;

  @override
  State<RefreshIndicator> createState() => _RefreshIndicatorState();
}

class _RefreshIndicatorState extends State<RefreshIndicator> {
  ScrollPhysics getScrollPhysics() {
    return ScrollConfiguration.of(context).getScrollPhysics(context);
  }

  bool get isBouncing => getScrollPhysics() is BouncingScrollPhysics;

  @override
  Widget build(BuildContext context) {
    final RefreshIndicatorType current =
        widget.type ??
        (isBouncing
            ? RefreshIndicatorType.bouncing
            : RefreshIndicatorType.clamping);

    if (current == RefreshIndicatorType.clamping) {
      return ClampingRefreshIndicator(
        onRefresh: widget.onRefresh,
        child: widget.child,
      );
    } else {
      return BouncingRefreshIndicator(
        onRefresh: widget.onRefresh,
        child: widget.child,
      );
    }
  }
}
