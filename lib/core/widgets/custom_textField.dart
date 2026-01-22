/*
import 'package:flutter/material.dart';

class ScannerTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;

  const ScannerTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        validator: validator,
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        focusNode: focusNode,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(
          color: enabled ? Colors.black : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.blueAccent : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: enabled ? Colors.blueAccent : Colors.grey),
          filled: true,
          fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';

class ScannerTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const ScannerTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        validator: validator,
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        focusNode: focusNode,
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: enabled ? Colors.black : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.blueAccent : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: enabled ? Colors.blueAccent : Colors.grey),
          suffixIcon: enabled ? suffixIcon : null,
          filled: true,
          fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
        ),
      ),
    );
  }
}