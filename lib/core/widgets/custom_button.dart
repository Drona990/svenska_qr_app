import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double width;
  final double height;
  final FontWeight fontWeight;
  final double fontSize;
  final double? borderRadius;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.borderColor = Colors.transparent,
    this.width = 200,
    this.height = 50,
    this.fontWeight = FontWeight.bold,
    this.fontSize = 16.0,
    this.borderRadius = 10.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isEnabled ? backgroundColor : Colors.grey,
          border: Border.all(
            color: isEnabled ? borderColor : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(borderRadius!),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius!),
            child: Center(
              child: isLoading
                  ? SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}