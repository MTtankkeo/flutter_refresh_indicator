import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_refresh_indicator/flutter_refresh_indicator.dart';

enum RefreshIndicatorType {
  clamping,
  bouncing
}

class RefreshIndicator extends StatefulWidget {
  const RefreshIndicator({
    super.key,
    this.type,
    required this.onRefresh,
    required this.child
  });

  final RefreshIndicatorType? type;
  final AsyncCallback onRefresh;
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
    final RefreshIndicatorType current = widget.type ?? (isBouncing
      ? RefreshIndicatorType.bouncing
      : RefreshIndicatorType.clamping
    );
    
    if (current == RefreshIndicatorType.clamping) {
      return ClampingRefreshIndicator(onRefresh: widget.onRefresh, child: widget.child);
    } else {
      return BouncingRefreshIndicator(onRefresh: widget.onRefresh, child: widget.child);
    }
  }
}