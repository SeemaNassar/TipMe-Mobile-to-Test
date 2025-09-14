//lib/reciver/onboarding_screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/routs/app_routs.dart';
import 'package:tipme_app/utils/colors.dart';
import 'package:tipme_app/utils/text_styles.dart';
import '../../data/services/language_service.dart';
import 'commons.dart';
import 'package:intl/intl.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40),
          child: Column(
            children: [
              SizedBox(height: isMobile ? 16 : 24),
              
              // Language toggle
              _buildLanguageSelector(context, isMobile),
              
              SizedBox(height: isMobile ? 60 : 80),
              
              // Logo section
              _buildLogoSection(isMobile, isTablet),
              
              // Flexible spacer
              Expanded(child: SizedBox()),
              
              // Bottom section
              _buildBottomSection(context, isMobile, isTablet, isSmallScreen),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, bool isMobile) {
    return Container(
      width: isMobile ? 185 : 220,
      height: isMobile ? 36 : 44,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildLanguageButton(context, 'en', isMobile),
          _buildLanguageButton(context, 'ar', isMobile),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context, String languageCode, bool isMobile) {
    final languageService = Provider.of<LanguageService>(context);
    final isSelected = languageService.currentLanguage == languageCode;
    final buttonText = languageCode == 'en'
        ? languageService.getText('english')
        : languageService.getText('arabic');

    return Expanded(
      child: GestureDetector(
        onTap: () => languageService.loadLanguage(languageCode),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              buttonText,
              style: isSelected
                  ? AppTextStyles.languageToggleActive(context)
                  : AppTextStyles.languageToggleInactive(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isMobile, bool isTablet) {
    final logoSize = isMobile ? 96.49 : (isTablet ? 120.0 : 150.0);
    final bgSize = isMobile ? 332.81 : (isTablet ? 400.0 : 450.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.3,
          child: Image.asset(
            'assets/images/freepik--Graphics--inject-11.png',
            width: bgSize,
            height: bgSize * 0.89,
            fit: BoxFit.contain,
          ),
        ),
        Column(
          children: [
            Image.asset(
              'assets/images/Isolation_Mode.png',
              width: logoSize,
              height: logoSize * 0.96,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSection(
      BuildContext context, bool isMobile, bool isTablet, bool isSmallScreen) {
    final languageService = Provider.of<LanguageService>(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageService.getText('welcomeTitle'),
            style: AppTextStyles.welcomeTitle(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          languageService.getArabicTextWithEnglish(
            'welcomeSubtitle',
            style: AppTextStyles.welcomeSubtitle(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 32 : 40),
          CreateAccountButton(
            text: languageService.getText('createAccount'),
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.stepsScreen,
            ),
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 24),
          _buildSignInText(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildSignInText(BuildContext context, bool isMobile) {
    final languageService = Provider.of<LanguageService>(context);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.signInUp),
      child: RichText(
        text: TextSpan(
          text: languageService.getText('alreadyHaveAccount'),
          style:
              AppTextStyles.bodyMedium(context, color: const Color(0XFF666666)),
          children: [
            TextSpan(
              text: languageService.getText('signIn'),
              style: AppTextStyles.link(context),
            ),
          ],
        ),
      ),
    );
  }
}
