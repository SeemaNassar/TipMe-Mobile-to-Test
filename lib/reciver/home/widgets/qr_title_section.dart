import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/data/services/language_service.dart';
import 'package:tipme_app/utils/colors.dart';
import 'package:tipme_app/utils/text_styles.dart';

class QRTitleSection extends StatelessWidget {
  const QRTitleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    return Container(
      width: 283,
      height: 70,
      alignment: Alignment.center,
      child: Text(
        languageService.getArabicTextWithEnglishString('generatingQR'),
        style:AppTextStyles.welcomeTitle(context, color: AppColors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}