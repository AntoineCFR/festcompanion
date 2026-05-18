import 'package:flutter/material.dart';

class DJBio extends StatelessWidget {
  final String bio;

  const DJBio({super.key, required this.bio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        bio,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}