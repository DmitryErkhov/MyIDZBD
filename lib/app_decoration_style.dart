import 'package:flutter/material.dart';
import 'app_color_style.dart';

class CustomDecorationStyle {

  static BoxDecoration shadowRectangle = BoxDecoration(
    color: CustomColorStyle.backGroundWhite,
    boxShadow: [
      BoxShadow(
        color: Color(0xFF000000).withOpacity(0.05),
        blurRadius: 5,
        spreadRadius: 2,
        offset: Offset(0,-4)
      ),
      BoxShadow(
        color: Color(0xFF000000).withOpacity(0.05),
        blurRadius: 5,
        spreadRadius: 2,
        offset: Offset(0,4)
      ),
    ],
  );

  static BoxDecoration shadowWithRadiusRectangle = BoxDecoration(
    color: CustomColorStyle.backGroundWhite,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,-4)
      ),
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,4)
      ),
    ],
  );

  static BoxDecoration gridRectangle = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: CustomColorStyle.backGroundWhite,
    boxShadow: [
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,-4)
      ),
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,4)
      ),
    ],
  );

  static BoxDecoration mapRectangle = BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/map.PNG'),
      fit: BoxFit.cover,
    ),
    color: CustomColorStyle.backGroundWhite,
    boxShadow: [
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,-4)
      ),
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,4)
      ),
    ],
  );

  static BoxDecoration downloadRectangle = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: CustomColorStyle.titleColor,
    boxShadow: [
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,-4)
      ),
      BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0,4)
      ),
    ],
  );
}