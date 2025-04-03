import 'package:flutter/material.dart';
import 'ipset.dart';
import 'add_sales.dart';// Ensure this file exists
import 'package:my_g/review.dart';

void main() {
  runApp(const my_g());
}

class my_g extends StatefulWidget {
  const my_g({super.key});

  @override
  State<my_g> createState() => _my_gState();
}

class _my_gState extends State<my_g> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.red),
      home: const ipset(),
      routes: {
        '/add_sales': (context) => AddSalesPage(), // Added named route
        '/reviewpage': (context) => ReviewsPage(),
      },
    );
  }
}
