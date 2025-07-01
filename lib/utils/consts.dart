import 'dart:io';

import 'package:chat_messaging_firebase/model/users.dart';
import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';
extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => theme.textTheme;
  double get devicePaddingTop => MediaQuery.of(this).padding.top;
  double get devicePaddingBottom => MediaQuery.of(this).padding.bottom;
  double get viewInsets => MediaQuery.of(this).viewInsets.bottom;
  double get deviceHeight => MediaQuery.of(this).size.height;
  double get deviceWidth => MediaQuery.of(this).size.width;
  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    FocusScope.of(this).unfocus();
  }

  String getInitials(String name) {
    var nameParts = name.split(' ');
    var firstNameInitial = '';
    var lastNameInitial = '';

    if (nameParts.isEmpty || name == '') {
      return '';
    } else if (nameParts.length == 1) {
      return firstNameInitial = nameParts[0][0].toUpperCase();
    } else {
      firstNameInitial = nameParts[0][0].toUpperCase();
      lastNameInitial = nameParts.last[0].toUpperCase();

      return firstNameInitial + lastNameInitial;
    }
  }

  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

enum MenuOption { edit, delete }

Widget showCustomPopup() {
  return PopupMenuButton<MenuOption>(
    icon: Icon(Icons.more_vert_outlined, size: 18),
    onSelected: (MenuOption selected) {
      switch (selected) {
        case MenuOption.edit:
          // your edit logic
          break;
        case MenuOption.delete:
          // your delete logic
          break;
      }
    },
    itemBuilder:
        (BuildContext context) => [
          PopupMenuItem(
            value: MenuOption.edit,
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: MenuOption.delete,
            child: Row(
              children: [
                Icon(Icons.delete, size: 16),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
  );
}

showSnackBarError(String? message) {
  Get.rawSnackbar(
    messageText: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // Add margin here
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Customize padding
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      child: Text(
        message ?? 'Operation not perform',
        style: const TextStyle(
          color: bgColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.transparent,
    // Set background to transparent to avoid overlap
    padding:
        EdgeInsets.zero, // Remove padding as it's handled inside the Container
  );
}

showSnackBarSuccess(String? message) {
  Get.rawSnackbar(
    messageText: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // Add margin here
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Customize padding
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      child: Text(
        message ?? 'Operation performed',
        style: const TextStyle(
          color: bgColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.transparent,
    // Set background to transparent to avoid overlap
    padding:
        EdgeInsets.zero, // Remove padding as it's handled inside the Container
  );
}

showPopupMenu(
  BuildContext context,
  TapDownDetails details,
  List<String> filterList,
  Function(String) click,
) {
  showMenu<String>(
    context: context,
    color: primaryColor,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    position: RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      details.globalPosition.dx,
      details.globalPosition.dy,
    ),
    items: List.generate(
      filterList.length,
      (index) => PopupMenuItem<String>(
        value: '1',
        height: 30,
        onTap: () => click(filterList[index]),
        // padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Center(
          child: Text(
            filterList[index],
            style: const TextStyle(color: bgColor, fontSize: 10),
          ),
        ),
      ),
    ),
  );
}

var languagesList = ["English", "Spanish", "French", "German"].obs;
var carerTypeList =
    [
      "Single",
      "Married",
      "Caregiver",
      "Mum",
      "Dad",
      "Foster Parent",
      "Grandparent",
      "Same Sex Parents",
      "LGBTQIA Family",
    ].obs;

var iWantToSee =
    [
      "Other Single Mums",
      "Breast Feeding",
      "Pumping/Bottle Feeding",
      "Formula/Bottle Feeding",
      "BLW (Baby Lead weaning)",
      "Mixed Feeding",
      "Solids",
      "Traditional vs Western medicine",
      "The Montessori method",
      "Weaning",
      "I have experienced a loss and want to connect with others who have been through similar experiences.",
    ].obs;

var iLookingFor = ["Meetups", "Online Chats", "I'm not looking to connect"].obs;

var matchMeBasedOn =
    [
      "My Age",
      "Trimester",
      "Age of child/ren",
      "What brings me here",
      "What I'm looking for",
      "Family compliment",
      "My Struggles",
      "Carer Type",
      "What I'm Practising",
    ].obs;

var iHaveList =
    [
      "Pregnant",
      "Trying to Conceive",
      "New Born Under 6 Months",
      "I have Multiple Children",
    ].obs;

var filterList =
    [
      "Pregnant",
      "Newborn under 6 months",
      "Infant 6-12 months",
      "Baby age 1-2 years",
      "Toddler  aged 2-3 years",
      "Child aged 3-5 years",
      "I have multiple children",
      'Trying to Conceive',
    ].obs;

var whatsBringsList =
    [
      "I want to see who's up when i am,just for fun",
      "I want to connect with my friends who are also checked in.",
      "I want to see if others are feeling like me today.",
      "I'm looking to connect with other people in the same season as me, practising the same things.",
      "I'm looking to connect with other people going through the same struggles.",
      "I'd like to find helpful content.",
    ].obs;

var likeList = [
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'sarahjhon12@gmail.com',
  ),
  Users(
    name: 'TAHLIA THOMAS',
    image: 'assets/images/user1.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'tahliathomas12@gmail.com',
  ),
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'sarahjhon12@gmail.com',
  ),
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'sarahjhon12@gmail.com',
  ),
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
  ),
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'sarahjhon12@gmail.com',
  ),
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'sarahjhon12@gmail.com',
  ),
  Users(
    name: 'TAHLIA THOMAS',
    image: 'assets/images/user1.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'tahliathomas12@gmail.com',
  ),
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'sarahjhon12@gmail.com',
  ),
  Users(
    name: 'TAHLIA THOMAS',
    image: 'assets/images/user1.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'tahliathomas12@gmail.com',
  ),
  Users(
    name: 'SARAH JOHNSON',
    image: 'assets/images/user2.png',
    isOnline: true,
    message: 'Infant 6-12 months',
    others: '',
    time: '',
    email: 'sarahjhon12@gmail.com',
  ),
];


class Consts {
  /// Image Picker ///
  static Future<File?> imageFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxHeight: 600,
      maxWidth: 800,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      return cropFile(pickedFile);
    }
    return null;
  }

  static Future<File?> imageFromCamera() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 600,
      maxWidth: 800,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      return cropFile(pickedFile);
    }
    return null;
  }

  static Future<File?> cropFile(XFile? file) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file!.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 70,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Image Cropper',
          toolbarColor: primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Image Cropper'),
      ],
    );

    return File(croppedFile!.path);
  }

  /// Date Formats //////////////////////////////////////
  static String parseTimeStamp(int value) {
    var date = DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    var d12 = DateFormat('hh:mm a').format(date);
    return d12;
  }

  static String parseTimeHH(int value) {
    var date = DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    var d12 = DateFormat('HH:mm').format(date);
    return d12;
  }

  static String parseTimeStamp1(int value) {
    var date = DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    var d12 = DateFormat('hh:mm a, MMM dd').format(date);
    return d12;
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss').format(dateTime);
  }

  static String formatDateTimeToMMM(String dateTime) {
    var date = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTimeToHHMM(String dateTime) {
    var date = DateTime.parse(dateTime);
    return DateFormat('hh:mm a').format(date);
  }
}

const String dummyProfile = "assets/images/dummy_profile.jpeg";
