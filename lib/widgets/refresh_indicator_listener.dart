import 'package:flutter/widgets.dart';

/// A widget that listens to global pointer events such as touch
/// and mouse input, and notifies its callbacks accordingly.
///
/// Typically used internally by refresh indicators to detect
/// user interactions like pull gestures or pointer releases.
@protected
class RefreshIndicatorListener extends StatefulWidget {
  const RefreshIndicatorListener({
    super.key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    required this.child,
  });

  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerCancelEventListener? onPointerCancel;
  final Widget child;

  @override
  State<RefreshIndicatorListener> createState() =>
      _RefreshIndicatorListenerState();
}

class _RefreshIndicatorListenerState extends State<RefreshIndicatorListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.pointerRouter.removeGlobalRoute(
      _handlePointerEvent,
    );
    super.dispose();
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      widget.onPointerDown?.call(event);
    } else if (event is PointerMoveEvent) {
      widget.onPointerMove?.call(event);
    } else if (event is PointerUpEvent) {
      widget.onPointerUp?.call(event);
    } else if (event is PointerCancelEvent) {
      widget.onPointerCancel?.call(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
