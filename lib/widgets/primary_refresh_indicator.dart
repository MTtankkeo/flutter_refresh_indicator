import 'package:flutter/material.dart';
import 'package:flutter_refresh_indicator/flutter_refresh_indicator.dart';

/// A inherited widget globally provides the style information for
/// refresh indicators to all descendant widgets in the widget tree.
class PrimaryRefreshIndicator extends InheritedWidget {
  const PrimaryRefreshIndicator({
    super.key,
    this.clampingIndicatorBuilder,
    this.bouncingIndicatorBuilder,
    required super.child,
  });

  /// The builder that will be defined to refresh indicator for [ClampingScrollPhysics].
  final ClampingRefreshIndicatorBuilder? clampingIndicatorBuilder;

  /// The builder that will be defined to refresh indicator for [BouncingScrollPhysics].
  final BouncingRefreshIndicatorBuilder? bouncingIndicatorBuilder;

  @override
  bool updateShouldNotify(PrimaryRefreshIndicator oldWidget) {
    return oldWidget.clampingIndicatorBuilder != clampingIndicatorBuilder ||
        oldWidget.bouncingIndicatorBuilder != bouncingIndicatorBuilder;
  }

  /// Finds the [PrimaryRefreshIndicator] from the closest instanc
  /// of this class that encloses the given context.
  static PrimaryRefreshIndicator? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PrimaryRefreshIndicator>();
  }
}
