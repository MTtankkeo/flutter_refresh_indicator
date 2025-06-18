import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:flutter_refresh_indicator/flutter_refresh_indicator.dart';

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
          child: RefreshIndicator(
            onRefresh: () => Future.delayed(Duration(milliseconds: 1000)),
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                return Container(
                  color: index % 2 == 0 ? Colors.red : Colors.blue,
                  height: 50,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
