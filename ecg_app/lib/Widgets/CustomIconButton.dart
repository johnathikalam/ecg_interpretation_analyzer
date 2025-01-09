import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final  Icon icon;
  final VoidCallback onPressed;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.top,
    this.right,
    this.bottom,
    this.left
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
      top: top,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color:Colors.grey.withOpacity(.15)
        ),
        child: IconButton(
            onPressed: onPressed,
            icon: icon
        ),
      ),
    );
  }
}
