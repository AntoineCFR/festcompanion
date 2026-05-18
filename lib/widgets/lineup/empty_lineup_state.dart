import 'package:flutter/material.dart';

class EmptyLineupState extends StatelessWidget {
  const EmptyLineupState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Aucun DJ à afficher.'));
  }
}