import 'package:flutter/material.dart';
import 'package:flutter_refresh_indicator/components/refresh_indicator_style.dart';

class PrimaryRefreshIndicator extends InheritedWidget {
  const PrimaryRefreshIndicator({
    super.key, 
    this.clamping,
    this.bouncing,
    required super.child,
  });

  final RefreshIndicatorStyle? clamping;
  final RefreshIndicatorStyle? bouncing;

  @override
  bool updateShouldNotify(PrimaryRefreshIndicator oldWidget) {
    return oldWidget.clamping != clamping
        || oldWidget.bouncing != bouncing;
  }

  static PrimaryRefreshIndicator? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PrimaryRefreshIndicator>();
  }
}