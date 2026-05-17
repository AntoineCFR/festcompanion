import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.maybeOf(this)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}