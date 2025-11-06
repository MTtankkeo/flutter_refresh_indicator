import 'package:flutter/widgets.dart';

/// A widget that measures the size of its [child] after layout
/// and reports it through the [onSize] callback.
class RefreshIndicatorSize extends StatefulWidget {
  const RefreshIndicatorSize({
    super.key,
    required this.onSize,
    required this.child,
  });

  /// Called after the widget has been laid out,
  /// providing the actual [Size] of the [child].
  final ValueChanged<Size> onSize;

  /// The widget whose size should be measured.
  final Widget child;

  @override
  State<RefreshIndicatorSize> createState() => _RefreshIndicatorSizeState();
}

class _RefreshIndicatorSizeState extends State<RefreshIndicatorSize> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Schedule a callback after the first frame to measure the child's size.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderbox =
          _globalKey.currentContext?.findRenderObject() as RenderBox;
      assert(renderbox.hasSize);
      widget.onSize(renderbox.size);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wraps the child with a GlobalKey to access its RenderBox.
    return KeyedSubtree(key: _globalKey, child: widget.child);
  }
}
