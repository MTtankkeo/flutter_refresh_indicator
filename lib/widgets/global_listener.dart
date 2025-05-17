import 'package:flutter/material.dart';

class GlobalListener extends StatefulWidget {
  const GlobalListener({
    super.key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    required this.child
  });

  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerCancelEventListener? onPointerCancel;
  final Widget child;

  @override
  State<GlobalListener> createState() => _GlobalListenerState();
}

class _GlobalListenerState extends State<GlobalListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
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