import 'package:flutter/material.dart';

import 'app_color_style.dart';

class CustomTextStyle {
  static TextStyle titleAuthPage(Size screenSize){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: CustomColorStyle.titleColor,
      fontSize: screenSize.width/60,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle hintTextFieldAuthPage(Size screenSize){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: CustomColorStyle.greyColor,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/120 < 16 ? 16 : screenSize.width/120 : screenSize.width/60 < 16 ? 16 : screenSize.width/60,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle textInTextFieldAuthPage(Size screenSize){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: CustomColorStyle.textColor,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/120 < 16 ? 16 : screenSize.width/120 : screenSize.width/60 < 16 ? 16 : screenSize.width/60,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle textButtonAuthPage(Size screenSize, Color colorText){
    return TextStyle(
      fontFamily: 'Tilda',
      color: colorText,
      fontSize: screenSize.width/120 - 1,
      fontWeight: FontWeight.w100,
    );
  }

  static TextStyle outlinedButtonAuthPage(Size screenSize){
    return TextStyle(
      fontFamily: 'Tilda',
      color: CustomColorStyle.textColor,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/96 < 16 ? 16 : screenSize.width/96 : screenSize.width/40 < 16 ? 16 : screenSize.width/40,
      fontWeight: FontWeight.w100,
    );
  }

  static TextStyle helloTitleHomePage(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: color,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/48 : screenSize.height/35,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle typeTitleHomePage(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: color,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/70 < 25 ? 30 : screenSize.width/70 : screenSize.width/35 < 25 ? 28 : screenSize.width/35,
      // fontSize: screenSize.width > screenSize.height ? screenSize.width/70 : screenSize.height/50,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle nameStepHomePage(Size screenSize, Color colorText){
    return TextStyle(
      fontFamily: 'Tilda',
      color: colorText,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/120 < 14 ? 20 : screenSize.width/120 : screenSize.width/60 < 14 ? 20 : screenSize.width/60,
      fontWeight: FontWeight.w300,
    );
  }

  static TextStyle countStepHomePage(Size screenSize, Color colorText){
    return TextStyle(
      fontFamily: 'Tilda',
      color: colorText,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/190 < 10 ? 14 : screenSize.width/190 : screenSize.width/95 < 10 ? 13 : screenSize.width/95,
      fontWeight: FontWeight.w300,
    );
  }


  // Стили виджетов

  static TextStyle countTitleCounterSectionWidget(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: color,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/48 < 25 ? 35 : screenSize.width/48 : screenSize.width/24 < 25 ? 35 : screenSize.width/24,
      height: 0,
      // fontSize: screenSize.width > screenSize.height ? screenSize.width/70 : screenSize.height/50,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle nameSubtitleCounterSectionWidget(Size screenSize, Color colorText){
    return TextStyle(
      fontFamily: 'Tilda',
      color: colorText,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/120 < 14 ? 14 : screenSize.width/120 : screenSize.width/60 < 14 ? 14 : screenSize.width/60,
      fontWeight: FontWeight.w100,
    );
  }

  static TextStyle navTitleNavMenyWidget(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: color,
      fontSize: 20,
      height: 0,
      fontWeight: FontWeight.w500,
    );
  }

  // Универсальные стили - Заголовки

  static TextStyle titleCardWidget(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Tilda',
      color: color,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/128 < 14 ? 18 : screenSize.width/128 : screenSize.width/64 < 14 ? 18 : screenSize.width/64,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle secondLigthInformationCardWidget(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Tilda',
      color: color,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/128 < 14 ? 16 : screenSize.width/128 : screenSize.width/64 < 14 ? 16 : screenSize.width/64,
      fontWeight: FontWeight.w100,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle secondBoldInformationCardWidget(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Tilda',
      color: color,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/155 < 11 ? 13 : screenSize.width/160 : screenSize.width/75 < 10 ? 13 : screenSize.width/80,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle subTitleCardWidget(Size screenSize, Color color){
    return TextStyle(
      fontFamily: 'Tilda',
      color: color,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/160 < 12 ? 14 : screenSize.width/160 : screenSize.width/80 < 12 ? 14 : screenSize.width/80,
      fontWeight: FontWeight.w200,
    );
  }

  static TextStyle titleRightDialog(Size screenSize, Color colorText){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: colorText,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/110 < 19 ? 20 : screenSize.width/110 : screenSize.width/60 < 19 ? 20 : screenSize.width/55,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle hintTitleLicensePlate(Size screenSize){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: CustomColorStyle.greyColor,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/120 < 16 ? 16 : screenSize.width/120 : screenSize.width/60 < 16 ? 16 : screenSize.width/60,
      // fontSize: screenSize.width > screenSize.height ? screenSize.width/70 : screenSize.height/50,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle titleLicensePlate(Size screenSize){
    return TextStyle(
      fontFamily: 'Evolventa',
      color: CustomColorStyle.titleColor,
      fontSize: screenSize.width > screenSize.height ? screenSize.width/120 < 16 ? 16 : screenSize.width/120 : screenSize.width/60 < 16 ? 16 : screenSize.width/60,
      // fontSize: screenSize.width > screenSize.height ? screenSize.width/70 : screenSize.height/50,
      fontWeight: FontWeight.w900,
    );
  }





  // Универсальные стили - Текстовое содержание

}