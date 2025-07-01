import 'package:flutter/material.dart';

class CommonSearchField extends StatelessWidget {
  const CommonSearchField(
      {super.key,
      this.controller,
      required this.hintText,
      this.onChanges,
      this.clear,
      this.isClearIcon,
      this.onEditingComplete,
      this.focusNode,
      this.onChanged,
      this.onFieldSubmitted});

  final TextEditingController? controller;
  final String hintText;
  final Function(String)? onChanges;
  final Function()? onEditingComplete;
  final VoidCallback? clear;
  final bool? isClearIcon;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.text,
      textAlign: TextAlign.start,
      textInputAction: TextInputAction.search,
      controller: controller,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      //onEditingComplete: onEditingComplete,
      //onChanged: onChanges,
      decoration: InputDecoration(
        fillColor: const Color(0xfffff6de),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            width: 0.0,
            color: const Color(0xfffff6de), // Focus border color
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            width: 0.0,
            color: const Color(0xfffff6de), // Default border color
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            width: 1.0,
            color: Colors.redAccent, // Error border color
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            width: 1.0,
            color: Colors.redAccent, // Focused error border color
          ),
        ),
        counterText: '',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          // color: hintTextColor,
          // fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
