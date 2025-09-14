//lib\services\language_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LanguageService with ChangeNotifier {
  Map<String, dynamic> _currentStrings = {};
  String _currentLanguage = 'en';

  Map<String, dynamic> get currentStrings => _currentStrings;
  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    String jsonString =
        await rootBundle.loadString('assets/translation/$languageCode.json');
    _currentStrings = json.decode(jsonString);
    notifyListeners();
  }

  String getText(String key) {
    return _currentStrings[key]?.toString() ?? key;
  }

  String getTextWithBiDi(String key) {
    final text = getText(key);
    
    if (_currentLanguage != 'ar') {
      return text;
    }
    
    // Unicode Bidi characters 
    return '\u202B$text\u202C'; // RLE + text + PDF
  }

  String getTextWithSmartBiDi(String key) {
    final text = getText(key);
    
    if (_currentLanguage != 'ar') {
      return text;
    }
    
    bool hasLatinCharacters = RegExp(r'[a-zA-Z0-9]').hasMatch(text);
    
    if (hasLatinCharacters) {
      // RLM (Right-to-Left Mark) 
      return text
          .replaceAllMapped(RegExp(r'([a-zA-Z0-9]+)'), (match) => '\u200F${match.group(0)}\u200F')
          .replaceAll('\u200F\u200F', '\u200F');
    }
    
    return text;
  }

  // Singleton pattern
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal() {
    loadLanguage(_currentLanguage);
  }

  List<Map<String, String>> getSteps() {
    List<dynamic> stepsList = _currentStrings['steps'] ?? [];
    return stepsList
        .map((step) => {
              "title": step['title']?.toString() ?? "",
              "description": step['description']?.toString() ?? "",
              "image": step['image']?.toString() ?? "",
            })
        .toList();
  }

  String getArabicTextWithEnglishString(String textKey) {
    final text = getText(textKey);
    
    if (currentLanguage != 'ar') {
      return text;
    }

    // Unicode BiDi characters 
    return '\u202B$text\u202C';
  }

  Widget getArabicTextWithEnglish(String textKey, {TextStyle? style, TextAlign textAlign = TextAlign.start}) {
    final text = getText(textKey);
    
    if (currentLanguage != 'ar') {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
      );
    }

    return RichText(
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        text: text,
        style: style,
      ),
    );
  }
}