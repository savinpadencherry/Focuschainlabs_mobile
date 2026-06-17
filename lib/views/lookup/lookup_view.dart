import 'package:flutter/material.dart';

class LookupView extends StatelessWidget {
  const LookupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Mr. Rex')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ask about a client, deal, or product',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}
