import 'package:flutter/material.dart';

import '../../../../theme/app_color.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final Function(T?) onChanged;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: Color(0xFF838E9E)
        ),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
      dropdownColor: Colors.white,
    );
  }
}
