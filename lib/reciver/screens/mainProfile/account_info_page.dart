// lib/reciver/screens/mainProfile/account_info_page.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/core/dio/service/api-service_path.dart';
import 'package:tipme_app/di/gitIt.dart';
import 'package:tipme_app/reciver/widgets/mainProfile_widgets/action_button.dart';
import 'package:tipme_app/reciver/widgets/mainProfile_widgets/bottom_sheet.dart';
import 'package:tipme_app/data/services/language_service.dart';
import 'package:tipme_app/reciver/widgets/phone_input.dart';
import 'package:tipme_app/services/authTipReceiverService.dart';
import 'package:tipme_app/services/tipReceiverService.dart';
import 'package:tipme_app/utils/app_font.dart';
import 'package:tipme_app/utils/colors.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/wallet_widgets/custom_top_bar.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({Key? key}) : super(key: key);

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final tipReceiverService = sl<TipReceiverService>();
  final authTipReceiverService = sl<AuthTipReceiverService>();

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _selectedCountryCode = '+971';
  bool _hasProfileImage = false;
  String? _userId;
  String? _imagePath;
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _isImageChanged = false;

  bool _isPhoneVerified = false;
  String? _originalCountryCode;
  String? _originalPhoneNumber;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await tipReceiverService.GetMe();
      if (response != null && response.success) {
        final userData = response.data;
        _userId = userData?.id;
        _firstNameController.text = userData?.firstName ?? '';
        _surnameController.text = userData?.surName ?? '';
        _imageUrl =
            userData?.imagePath != null && userData!.imagePath!.isNotEmpty
                ? "${ApiServicePath.fileServiceUrl}/${userData.imagePath}"
                : null;
        _hasProfileImage = _imageUrl != null;

        final fullNumber = userData?.mobileNumber ?? '';
        if (fullNumber.isNotEmpty) {
          if (fullNumber.startsWith('+') && fullNumber.length > 3) {
            _selectedCountryCode = fullNumber.substring(0, 4);
            _originalCountryCode = _selectedCountryCode;

            _phoneController.text = fullNumber.substring(4).trim();
            _originalPhoneNumber = _phoneController.text;
          } else {
            _phoneController.text = fullNumber;
            _originalPhoneNumber = fullNumber;
          }
        }

        _isPhoneVerified = fullNumber.isNotEmpty;
        _imagePath = userData?.imagePath;
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        final languageService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(languageService.getText('failedToLoadUserData'))),
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

  Future<void> _updateProfile() async {
    if (_userId == null) return;

    if (mounted) {
      setState(() {
        _isUpdating = true;
      });
    }

    try {
      final cleanPhoneNumber = _phoneController.text.replaceAll(' ', '');
      final fullPhoneNumber = '$_selectedCountryCode$cleanPhoneNumber';
      final formData = FormData.fromMap({
        'firstName': _firstNameController.text,
        'surName': _surnameController.text,
        'mobileNumber': fullPhoneNumber,
        if (_imageFile != null && !kIsWeb)
          'image': await MultipartFile.fromFile(_imageFile!.path),
        if (_imageBytes != null && kIsWeb)
          'image':
              MultipartFile.fromBytes(_imageBytes!, filename: "profile.png"),
      });
      await authTipReceiverService.editProfile(_userId!, formData);
      if (mounted) {
        setState(() {
          _originalCountryCode = _selectedCountryCode;
          _originalPhoneNumber = _phoneController.text;
        });
      }

      if (mounted) {
        final languageService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(languageService.getText('profileUpdatedSuccessfully'))),
        );
        await _loadUserData();
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        final languageService =
            Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(languageService.getText('failedToUpdateProfile'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onChangeProfile() async {
    final languageService =
        Provider.of<LanguageService>(context, listen: false);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(languageService.getText('imageSizeTooLarge')),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            if (kIsWeb) {
              _imageBytes = file.bytes;
              _imageFile = null;
            } else {
              _imageFile = File(file.path!);
              _imageBytes = null;
            }
            _hasProfileImage = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${languageService.getText('errorSelectingImage')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDeleteProfile() {
    final languageService =
        Provider.of<LanguageService>(context, listen: false);

    SuccessBottomSheet.show(
      context,
      title: languageService.getText('deleteProfilePicture'),
      description: languageService.getText('deleteProfilePictureConfirmation'),
      primaryButtonText: languageService.getText('yesDelete'),
      secondaryButtonText: languageService.getText('noCancel'),
      icon: Icons.delete_outline,
      iconColor: AppColors.danger_500,
      iconBackgroundColor: AppColors.white,
      primaryButtonColor: AppColors.danger_500,
      primaryButtonTextColor: AppColors.white,
      secondaryButtonBorderColor: AppColors.border_2,
      secondaryButtonTextColor: AppColors.text,
      onPrimaryButtonPressed: () {
        Navigator.pop(context);
        if (mounted) {
          setState(() {
            _hasProfileImage = false;
            _imageFile = null;
            _imageBytes = null;
            _imageUrl = null;
          });
        }
      },
      onSecondaryButtonPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void _onPhoneChanged(String phone) {
    if (mounted) {
      setState(() {
        _phoneController.text = phone;
        _updateVerificationStatus();
      });
    }
  }

  void _onCountryChanged(String countryCode) {
    if (mounted) {
      setState(() {
        _selectedCountryCode = countryCode;
        _updateVerificationStatus();
      });
    }
  }

  void _updateVerificationStatus() {
    final bool isSameCountry = _selectedCountryCode == _originalCountryCode;
    final bool isSamePhone = _phoneController.text == _originalPhoneNumber;
    final bool isPhoneNotEmpty = _phoneController.text.isNotEmpty;

    if (mounted) {
      setState(() {
        if (isSameCountry && isSamePhone && isPhoneNotEmpty) {
          _isPhoneVerified = true;
        } else if (!isSameCountry || !isSamePhone) {
          if (_isPhoneVerified &&
              (_originalCountryCode != null && _originalPhoneNumber != null)) {
            _isPhoneVerified = false;
          }
        }
      });
    }
  }

  void _onUpdatePressed() {
    if (mounted) {
      _updateProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar.withTitle(
              title: Text(
                languageService.getText('accountInfo'),
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
            const SizedBox(height: 24),
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
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                  child: Column(
                    children: [
                      _buildProfileSection(languageService),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageService.getText('firstName'),
                                  style: AppFonts.mdSemiBold(context,
                                      color: AppColors.black),
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  hintText:
                                      languageService.getText('firstName'),
                                  controller: _firstNameController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageService.getText('surname'),
                                  style: AppFonts.mdSemiBold(context,
                                      color: AppColors.black),
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  hintText: languageService.getText('surname'),
                                  controller: _surnameController,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageService.getText('phoneNumber'),
                            style: AppFonts.smMedium(context,
                                color: AppColors.text),
                          ),
                          const SizedBox(height: 8),
                          CustomPhoneInput(
                            mode: PhoneInputMode.account,
                            phoneNumber: _phoneController.text,
                            selectedCountryCode: _selectedCountryCode ?? "+966",
                            isVerified: _isPhoneVerified,
                            onPhoneChanged: _onPhoneChanged,
                            onCountryChanged: _onCountryChanged,
                            onVerified: () {
                              if (mounted) {
                                setState(() {
                                  _isPhoneVerified = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      CustomButton(
                        text: languageService.getText('update'),
                        onPressed: _onUpdatePressed,
                        showArrow: true,
                        isLoading: _isUpdating,
                        isEnabled: _isPhoneVerified,
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

  Widget _buildProfileSection(LanguageService languageService) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                child: _hasProfileImage
                    ? (_imageBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              _imageBytes!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _imageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  _imageFile!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _imageUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[600],
                                  ))
                    : Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                    onPressed: _onChangeProfile,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActionButton(
              text: languageService.getText('change'),
              backgroundColor: AppColors.secondary_500.withOpacity(0.1),
              textColor: AppColors.secondary_500,
              svgIcon: 'assets/icons/pencil.svg',
              onPressed: _onChangeProfile,
            ),
            if (_hasProfileImage) ...[
              const SizedBox(width: 12),
              ActionButton(
                text: languageService.getText('delete'),
                backgroundColor: AppColors.danger_500.withOpacity(0.1),
                textColor: AppColors.danger_500,
                svgIcon: 'assets/icons/trash.svg',
                onPressed: _onDeleteProfile,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
