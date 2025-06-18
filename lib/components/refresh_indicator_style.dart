import 'package:flutter/cupertino.dart';

/// The data class that defines the style for referring in refresh indicator widgets.
class RefreshIndicatorStyle {
  const RefreshIndicatorStyle({this.backgroundColor, this.foregroundColor});

  /// The background color of the container that wrap the progress indicator.
  final Color? backgroundColor;

  /// The color of the progress indicator.
  final Color? foregroundColor;
}
