import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:flutter/material.dart';


class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    this.btnBgColor,
    this.btnTextColor,
    this.fontWeight,
    required this.btnText,
    required this.onClick,
    this.fontFamily,
    this.fontSize,
  });

  final Color? btnBgColor;
  final Color? btnTextColor;
  final double? fontSize;
  final String btnText;
  final VoidCallback onClick;
  final FontWeight? fontWeight;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onClick,
      style: ButtonStyle(
        elevation: WidgetStateProperty.all<double>(
          0, // Adjust padding as needed
        ),
        padding: WidgetStateProperty.all<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 14,vertical: 12), // Adjust padding as needed
        ),
        backgroundColor: WidgetStateProperty.all<Color>(
          btnBgColor ?? primaryColor,
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        overlayColor: WidgetStateProperty.all<Color>(
          Colors.transparent,
        ),
      ),

      child: Text(
        btnText.toUpperCase(),
        style: TextStyle(
          color: btnTextColor ?? Colors.black87,
          fontWeight: FontWeight.bold,
          fontFamily: 'OpenSans',
          fontSize: 18,
        ),
      ),
    );
  }
}

// ElevatedButton(
// onPressed: onClick,
// style: ButtonStyle(
// padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
// const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
// ),
// backgroundColor: WidgetStateProperty.all<Color>(
// btnBgColor ?? primaryColor,
// ),
// shape: WidgetStateProperty.all<RoundedRectangleBorder>(
// RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(16),
// ),
// ),
// overlayColor: WidgetStateProperty.all<Color>(
// Colors.transparent,
// ),
// ),
// child: Text(
// btnText.toUpperCase(),
// style: TextStyle(
// color: btnTextColor ?? bgColor,
// fontWeight: fontWeight ?? FontWeight.w700,
// fontSize: fontSize ?? 18,
// ),
// ),
// );
