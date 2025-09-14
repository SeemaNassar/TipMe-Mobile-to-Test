import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/core/dio/client/dio_client.dart';
import 'package:tipme_app/core/storage/storage_service.dart';
import 'package:tipme_app/di/gitIt.dart';
import 'package:tipme_app/services/tipReceiverService.dart';
import 'package:tipme_app/utils/app_font.dart';
import 'package:tipme_app/viewModels/verifyOtpData.dart';
import '../../../routs/app_routs.dart';
import '../../../utils/colors.dart';
import '../../../data/services/language_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input.dart';
import 'package:tipme_app/services/authTipReceiverService.dart';
import 'package:tipme_app/dtos/verifyOtpDto.dart';
import 'package:tipme_app/dtos/signInUpDto.dart';
import 'package:tipme_app/services/notificationInitializationService.dart';

class VerifyPhonePage extends StatefulWidget {
  final String phoneNumber;
  final bool isLogin;

  const VerifyPhonePage({
    Key? key,
    required this.phoneNumber,
    this.isLogin = false,
  }) : super(key: key);

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  String _otpCode = '';
  final int _otpLength = 6;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  bool _isTimerActive = true;
  int _remainingTime = 0;

  int _resendAttempts = 0;
  final int _maxResendAttempts = 3;
  bool _resendAttemptsExceeded = false;

  final GlobalKey<OtpInputState> _otpInputKey = GlobalKey<OtpInputState>();

  void _onOtpChanged(String value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _otpCode = value;
          _errorMessage = null;
        });
      }
    });
  }

  void _onTimerChanged(bool isActive, int remainingTime) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isTimerActive = isActive;
          _remainingTime = remainingTime;
        });
      }
    });
  }

  void _onVerifyPressed() async {
    if (_otpCode.length == _otpLength) {
      if (mounted) {
        setState(() {
          _isVerifying = true;
          _errorMessage = null;
        });
      }

      try {
        final service = AuthTipReceiverService(
            sl<DioClient>(instanceName: 'AuthTipReceiver'));
        final dto = VerifyOtpDto(
          mobileNumber: widget.phoneNumber,
          otp: _otpCode,
        );

        final response = widget.isLogin
            ? await service.verifyLoginOtp(dto)
            : await service.verifyOtp(dto);

        if (response.success) {
          await _saveUserData(response.data);

          if (widget.isLogin) {
            await NotificationInitializationService.instance
                .reinitializeAfterLogin();

            final service = sl<TipReceiverService>();
            var response = await service.GetMe();
            if (response!.data!.isCompleted == true) {
              Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.verificationPending);
              return;
            }
          }

          Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
        } else {
          final languageService =
              Provider.of<LanguageService>(context, listen: false);
          if (mounted) {
            setState(() {
              _errorMessage = response.message.isNotEmpty
                  ? response.message
                  : languageService.getText('verificationFailed');
            });
          }
        }
      } catch (e) {
        final languageService =
            Provider.of<LanguageService>(context, listen: false);
        if (mounted) {
          setState(() {
            _errorMessage = languageService.getText('errorOccurred');
          });
        }
        print("Verify OTP Error: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
        }
      }
    }
  }

  void _onResendCode() async {
    final languageService =
        Provider.of<LanguageService>(context, listen: false);

    if (_isTimerActive || _isResending || _resendAttemptsExceeded) {
      if (_resendAttemptsExceeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageService.getText('maxResendAttemptsExceeded')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _resendAttempts++;

    if (mounted) {
      setState(() {
        _isResending = true;
        _errorMessage = null;
      });
    }

    try {
      final service = AuthTipReceiverService(
          sl<DioClient>(instanceName: 'AuthTipReceiver'));
      final dto = SignInUpDto(mobileNumber: widget.phoneNumber);

      final response = widget.isLogin
          ? await service.login(dto)
          : await service.signUp(dto);

      if (response.success) {
        if (_resendAttempts >= _maxResendAttempts) {
          if (mounted) {
            setState(() {
              _resendAttemptsExceeded = true;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(languageService.getText('lastResendAttemptUsed')),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          int remainingAttempts = _maxResendAttempts - _resendAttempts;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(languageService
                  .getText('codeResentSuccessfully')
                  .replaceAll('{attempts}', remainingAttempts.toString())),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        _otpInputKey.currentState?.restartTimer();

        if (mounted) {
          setState(() {
            _otpCode = '';
            _isTimerActive = true;
          });
        }
      } else {
        _resendAttempts--;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty
                ? response.message
                : languageService.getText('failedToResendCode')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _resendAttempts--;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageService.getText('failedToResendCode')),
          backgroundColor: Colors.red,
        ),
      );
      print("Resend OTP Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _onEditNumber() {
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.white,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 80 : 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: isSmallScreen ? 10 : 20),
                    Image.asset(
                      'assets/images/Isolation_Mode.png',
                      width: isSmallScreen ? 48 : 58,
                      height: isSmallScreen ? 46 : 56,
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 40),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        languageService.getText('verifyPhoneTitle'),
                        style: AppFonts.h3(context, color: AppColors.white),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 400 : screenSize.width - 48,
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppFonts.mdMedium(context,
                              color: AppColors.white.withOpacity(0.9)),
                          children: [
                            TextSpan(
                              text: languageService
                                  .getText('verifyPhoneSubtitle'),
                            ),
                            TextSpan(
                              text: widget.phoneNumber,
                              style: AppFonts.mdSemiBold(context,
                                  color: AppColors.white.withOpacity(0.9)),
                            ),
                            const TextSpan(text: '" '),
                            TextSpan(
                              text: languageService.getText('editNumber'),
                              style: AppFonts.mdSemiBold(context,
                                  color: AppColors.primary),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _onEditNumber,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 30 : 50),
                    Container(
                      width: isTablet ? 400 : double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OtpInput(
                            key: _otpInputKey,
                            length: _otpLength,
                            onOtpChanged: _onOtpChanged,
                            otpCode: _otpCode,
                            onTimerChanged: _onTimerChanged,
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppFonts.smMedium(context,
                                          color: Colors.red.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          CustomButton(
                            text: _isVerifying
                                ? languageService.getText('verifying')
                                : languageService
                                    .getText('verifyPhoneNumber'),
                            onPressed: (_otpCode.length == _otpLength &&
                                    !_isVerifying)
                                ? _onVerifyPressed
                                : null,
                            isEnabled:
                                _otpCode.length == _otpLength && !_isVerifying,
                            showArrow: !_isVerifying,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            textDirection:
                                languageService.currentLanguage == 'ar'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                            children: [
                              languageService.getArabicTextWithEnglish(
                                'didntGetOtp',
                                style: AppFonts.mdMedium(context,
                                    color: Colors.grey[600]),
                              ),
                              Tooltip(
                                message: _resendAttemptsExceeded
                                    ? languageService
                                        .getText('maxResendAttemptsExceeded')
                                    : '',
                                decoration: BoxDecoration(
                                  color: Colors.red[800],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.all(8),
                                child: InkWell(
                                  onTap: (!_isTimerActive &&
                                          !_isResending &&
                                          !_resendAttemptsExceeded)
                                      ? _onResendCode
                                      : null,
                                  child: languageService
                                      .getArabicTextWithEnglish(
                                    _isResending ? 'sending' : 'resendCode',
                                    style: AppFonts.mdMedium(
                                      context,
                                      color: (_isTimerActive ||
                                              _isResending ||
                                              _resendAttemptsExceeded)
                                          ? Colors.grey[400]
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveUserData(VerifyOtpData? data) async {
    await StorageService.save('user_token', data?.token);
    await StorageService.save('user_id', data?.id);
    await StorageService.save('mobile_number', widget.phoneNumber);
    await StorageService.save('Currency', data?.currency);
  }
}
