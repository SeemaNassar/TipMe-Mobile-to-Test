// lib/auth/screens/profile/notification_preferences_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/core/dio/client/dio_client.dart';
import 'package:tipme_app/di/gitIt.dart';
import 'package:tipme_app/reciver/widgets/mainProfile_widgets/switch_card.dart';
import 'package:tipme_app/reciver/widgets/wallet_widgets/custom_top_bar.dart';
import 'package:tipme_app/services/settingsService.dart';
import 'package:tipme_app/utils/app_font.dart';
import 'package:tipme_app/utils/colors.dart';
import 'package:tipme_app/data/services/language_service.dart';
import 'package:tipme_app/viewModels/settingsData.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  late SettingsService _settingsService;
  late TipReceiveerSettingsData _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settingsService =
        SettingsService(sl<DioClient>(instanceName: 'TipReceiverSettings'));
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await _settingsService.getSettings();
      final settings = response?.data ??
          TipReceiveerSettingsData(
            notifyOnTipReceived: false,
            notifyOnTipGiven: false,
            notifyOnBankAccountVerification: false,
            notifyOnAnnouncement: false,
            enableBiometricLogin: false,
          );
      if (mounted) {
        setState(() {
          _settings = settings;
        });
      }
    } catch (e) {
      if (mounted) {
        final languageService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${languageService.getText('failedToLoadSettings')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      await _settingsService.updateSettings(_settings);
    } catch (e) {
      if (mounted) {
        final languageService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${languageService.getText('failedToSaveSettings')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
                languageService.getText('notificationPreferences'),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            SwitchCard(
                              text: languageService.getText('tipsReceived'),
                              value: _settings.notifyOnTipReceived,
                              onChanged: (value) async {
                                if (mounted) {
                                  setState(() {
                                    _settings.notifyOnTipReceived = value;
                                  });
                                }
                                await _saveSettings();
                              },
                            ),
                            SwitchCard(
                              text: languageService.getText('tipsGiven'),
                              value: _settings.notifyOnTipGiven,
                              onChanged: (value) async {
                                if (mounted) {
                                  setState(() {
                                    _settings.notifyOnTipGiven = value;
                                  });
                                }
                                await _saveSettings();
                              },
                            ),
                            SwitchCard(
                              text: languageService
                                  .getText('bankAccountVerification'),
                              value: _settings.notifyOnBankAccountVerification,
                              onChanged: (value) async {
                                if (mounted) {
                                  setState(() {
                                    _settings.notifyOnBankAccountVerification =
                                        value;
                                  });
                                }
                                await _saveSettings();
                              },
                            ),
                            SwitchCard(
                              text: languageService
                                  .getText('announcementAndOffers'),
                              value: _settings.notifyOnAnnouncement,
                              onChanged: (value) async {
                                if (mounted) {
                                  setState(() {
                                    _settings.notifyOnAnnouncement = value;
                                  });
                                }
                                await _saveSettings();
                              },
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
