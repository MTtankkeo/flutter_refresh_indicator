import 'package:flutter/material.dart';
import 'package:flutter_refresh_indicator/components/refresh_indicator_style.dart';

/// A inherited widget globally provides the style information for
/// refresh indicators to all descendant widgets in the widget tree.
class PrimaryRefreshIndicator extends InheritedWidget {
  const PrimaryRefreshIndicator({
    super.key,
    this.clamping,
    this.bouncing,
    required super.child,
  });

  /// The style that will be defined to refresh indicator for [ClampingScrollPhysics].
  final RefreshIndicatorStyle? clamping;

  /// The style that will be defined to refresh indicator for [BouncingScrollPhysics].
  final RefreshIndicatorStyle? bouncing;

  @override
  bool updateShouldNotify(PrimaryRefreshIndicator oldWidget) {
    return oldWidget.clamping != clamping || oldWidget.bouncing != bouncing;
  }

  /// Finds the [PrimaryRefreshIndicator] from the closest instanc
  /// of this class that encloses the given context.
  static PrimaryRefreshIndicator? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PrimaryRefreshIndicator>();
  }
}
