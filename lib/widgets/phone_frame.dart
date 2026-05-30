import 'package:flutter/material.dart';

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Container(
        width: 450,
        height: 900,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.black87, width: 8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, spreadRadius: 4)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: child,
        ),
      ),
    );
  }
}
