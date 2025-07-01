import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:flutter/material.dart';


class CommonTextFormField extends StatelessWidget {
  const CommonTextFormField({
    super.key,
    this.controller,
    required this.hintText,
    this.isReadOnly,
    this.textInputType,
    this.maxLength,
    this.validator,
    this.maxLine,
    this.color,
    this.hintTextColor,
    this.autovalidateMode,
    this.decoration,
    this.onTap,
  });

  final TextEditingController? controller;
  final int? maxLine;
  final int? maxLength;
  final bool? isReadOnly;
  final TextInputType? textInputType;
  final String hintText;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final AutovalidateMode? autovalidateMode;
  final VoidCallback? onTap;
  final Color? color;
  final Color? hintTextColor; // New parameter

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: textInputType ?? TextInputType.text,
      textInputAction: TextInputAction.done,
      maxLines: maxLine ?? 1,
      cursorColor: bgColor,
      onTap: onTap,
      readOnly: isReadOnly ?? false,
      autovalidateMode: autovalidateMode,
      maxLength: maxLength ?? TextField.noMaxLength,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
      ),
      decoration: decoration ??
          InputDecoration(
            fillColor: color ?? Color(0xfffff6de),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                width: 0.4,
                color: Colors.grey, // Focus border color
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                width: 0.4,
                color: Colors.grey, // Default border color
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                width: 1.0,
                color: Colors.redAccent, // Error border color
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
                fontSize: 16,
                color: hintTextColor,
                fontWeight: FontWeight.w500),
          ),
    );
  }
}
