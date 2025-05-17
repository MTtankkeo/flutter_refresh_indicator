import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appbar/flutter_appbar.dart';
import 'package:flutter_refresh_indicator/widgets/global_listener.dart';

class BouncingRefreshIndicator extends StatefulWidget {
  const BouncingRefreshIndicator({
    super.key,
    required this.onRefresh,
    this.foregroundColor,
    required this.child
  });

  final AsyncCallback onRefresh;
  final Color? foregroundColor;
  final Widget child;

  @override
  State<BouncingRefreshIndicator> createState() => _BouncingRefreshIndicatorState();
}

class _BouncingRefreshIndicatorState extends State<BouncingRefreshIndicator> {
  double _consumedPixels = 0;
  bool _isDragging = false;

  double get distanceFraction {
    return (-_consumedPixels / 100).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GlobalListener(
      onPointerCancel: (event) => _isDragging = false,
      onPointerDown: (event) => _isDragging = true,
      onPointerUp: (event) => _isDragging = false,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: CircularProgressIndicator(
                color: widget.foregroundColor,
                value: distanceFraction,
              ),
            ),
          ),
          Transform.translate(
            transformHitTests: false,
            offset: Offset(0, -_consumedPixels),
            child: NestedScrollConnection(
              onBouncing: (available, position) {
                setState(() => _consumedPixels += available);
                return available;
              },
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}