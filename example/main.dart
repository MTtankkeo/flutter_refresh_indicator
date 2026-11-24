import 'package:flutter_refresh_indicator/flutter_refresh_indicator.dart';
import 'package:material_ui/material_ui.dart' hide RefreshIndicator;

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Example(),
        ),
      ),
    );
  }
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => .delayed(.new(seconds: 1)),
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) {
          return Container(
            height: 50,
            color: index % 2 == 0 ? Colors.red : Colors.blue,
          );
        },
      ),
    );
  }
}
