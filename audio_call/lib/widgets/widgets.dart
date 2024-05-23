/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.

import 'package:audio_call/theme/voximplant_theme.dart';
import 'package:flutter/material.dart';

class Widgets {
  static Widget textFormField({
    required TextEditingController controller,
    required bool darkBackground,
    required String labelText,
    String? suffixText,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ),
      child: Theme(
        data: ThemeData(
          primaryColor:
              darkBackground ? VoximplantColors.white : VoximplantColors.button,
          // cursorColor:
          //     darkBackground ? VoximplantColors.white : VoximplantColors.button,
          hintColor:
              darkBackground ? VoximplantColors.white : VoximplantColors.button,
        ),
        child: TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: darkBackground
                    ? VoximplantColors.white
                    : VoximplantColors.button,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: darkBackground
                    ? VoximplantColors.white
                    : VoximplantColors.button,
              ),
            ),
            labelText: labelText,
            suffixText: suffixText,
          ),
          keyboardType: inputType,
          controller: controller,
          autocorrect: false,
          obscureText: obscureText,
          style: TextStyle(
            color: darkBackground ? VoximplantColors.white : null,
          ),
          validator: validator,
        ),
      ),
    );
  }

  static Widget maxWidthRaisedButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(color: VoximplantColors.white)),
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }

  static Widget textWithPadding({
    required String text,
    required Color textColor,
    double fontSize = 30.0,
    double verticalPadding = 0.0,
    double horizontalPadding = 0.0,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
        ),
      ),
    );
  }

  static Widget iconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Ink(
      decoration: const ShapeDecoration(
        color: VoximplantColors.white,
        shape: CircleBorder(),
      ),
      child: IconButton(
        onPressed: onPressed,
        iconSize: 40,
        icon: Icon(
          icon,
          color: color,
        ),
        tooltip: tooltip,
      ),
    );
  }

  static Widget dropdown(
      {required List<String> items,
      required ValueChanged<String?> onChange,
      String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ),
      child: Container(
          decoration: const ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  width: 1.0,
                  style: BorderStyle.solid,
                  color: VoximplantColors.white),
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
            ),
            // color: VoximplantColors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: DropdownButton<String>(
              value: value,
              style: const TextStyle(color: VoximplantColors.white),
              hint: const Text(
                'Connection node',
                style: TextStyle(color: VoximplantColors.white),
              ),
              isExpanded: true,
              dropdownColor: VoximplantColors.primary,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              alignment: AlignmentDirectional.center,
              onChanged: (String? node) {
                onChange(node);
              },
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
            ),
          )),
    );
  }
}
