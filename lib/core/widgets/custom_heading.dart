import 'package:flutter/material.dart';

class CustomHeading extends StatelessWidget {
  final String leftText;
  final String rightText;
  final TextStyle? leftTextStyle;
  final TextStyle? rightTextStyle;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final VoidCallback? onRightTextTap;

  const CustomHeading({
    super.key,
    required this.leftText,
    required this.rightText,
    this.leftTextStyle,
    this.rightTextStyle,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.onRightTextTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          leftText,
          style: leftTextStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onRightTextTap,
          child: Text(
            rightText,
            style: rightTextStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
