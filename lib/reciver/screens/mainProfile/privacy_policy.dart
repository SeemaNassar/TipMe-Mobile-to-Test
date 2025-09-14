//lib\reciver\screens\mainProfile\privacy_policy.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/core/dio/client/dio_client.dart';
import 'package:tipme_app/di/gitIt.dart';
import 'package:tipme_app/reciver/widgets/mainProfile_widgets/terms_section_card.dart';
import 'package:tipme_app/reciver/widgets/wallet_widgets/custom_top_bar.dart';
import 'package:tipme_app/services/appSettingsService.dart';
import 'package:tipme_app/utils/app_font.dart';
import 'package:tipme_app/utils/colors.dart';
import 'package:tipme_app/data/services/language_service.dart';
import 'package:tipme_app/viewModels/privacyPolicyData.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final AppSettingsService _appSettingsService;
  late Future<List<PrivacyPolicyData>> _privacyFuture;

  @override
  void initState() {
    super.initState();
    _appSettingsService =
        AppSettingsService(sl<DioClient>(instanceName: 'AppSettings'));
    _loadPrivacyPolicy();
  }

  void _loadPrivacyPolicy() {
    if (mounted) {
    setState(() {
      _privacyFuture = _appSettingsService.getPrivacyPolicyData(lang: 'en').then((response) {
        if (response.success && response.data != null) {
          return response.data!;
        } else {
          throw Exception('No Privacy Policy found');
        }
      });
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar.withTitle(
              title: Text(
                languageService.getText('privacyPolicy'),
                style: AppFonts.lgBold(context, color: AppColors.white),
              ),
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              showNotification: false,
              showProfile: false,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: FutureBuilder<List<PrivacyPolicyData>>(
                  future: _privacyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              languageService.getText('noPrivacyPolicyFound'),
                              style: AppFonts.mdMedium(context),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPrivacyPolicy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: Text(
                                languageService.getText('retry'),
                                style: AppFonts.smMedium(context,
                                    color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          languageService.getText('noPrivacyPolicyAvailable'),
                          style: AppFonts.mdMedium(context),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageService.getText('privacyLastUpdated'),
                                  style: AppFonts.mdBold(context,
                                      color: AppColors.black),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  languageService.getText('privacyIntro'),
                                  style: AppFonts.smRegular(
                                    context,
                                    color: AppColors.text,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ),
                          ),
                          ...snapshot.data!
                              .map((policy) => TermsSectionCard(
                                    title: policy.title,
                                    description: policy.description,
                                    isNumbered: policy.isNumbered,
                                    number: policy.number,
                                  ))
                              .toList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}