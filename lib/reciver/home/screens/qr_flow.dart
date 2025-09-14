import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tipme_app/core/dio/service/api-service_path.dart';
import 'package:tipme_app/core/storage/storage_service.dart';
import 'package:tipme_app/di/gitIt.dart';
import 'package:tipme_app/reciver/screens/wallet/notification_screen.dart';
import 'package:tipme_app/reciver/widgets/custom_bottom_navigation.dart';
import 'package:tipme_app/reciver/widgets/wallet_widgets/custom_top_bar.dart';
import 'package:tipme_app/reciver/widgets/wallet_widgets/available_balance_card.dart'; // Add this import
import 'package:tipme_app/reciver/home/screens/customize_qr_screen.dart';
import 'package:tipme_app/reciver/home/widgets/qr_content.dart';
import 'package:tipme_app/reciver/home/widgets/quick_icon.dart';
import 'package:tipme_app/routs/app_routs.dart';
import 'package:tipme_app/data/services/language_service.dart';
import 'package:tipme_app/services/tipReceiverService.dart';
import 'package:tipme_app/services/tipReceiverStatisticsService.dart';
import 'package:tipme_app/utils/colors.dart';
import 'package:tipme_app/utils/app_font.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';
import 'package:tipme_app/services/qrCodeService.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tipme_app/viewModels/tipReceiveerData.dart';

class HomeScreen extends StatefulWidget {
  final Uint8List? qrBytes;
  final String? qrDataUri;
  final Uint8List? logoBytes;

  const HomeScreen({
    super.key,
    this.qrBytes,
    this.qrDataUri,
    this.logoBytes,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Constants for layout measurements
  static const double _bgWidth = 332;
  static const double _bgHeight = 296;
  static const double _overlayDrop = 250;
  static const double _cardWidth = 338;
  static const double _overlayCardHeight = 340;
  int _currentBottomNavIndex = 0; // Set to qr tab (index 0)
  final bool _showNotifications = true;
  late TipReceiverStatisticsService _statisticsService;
  Uint8List? qrBytes;
  Uint8List? logoBytes;
  Uint8List? savedLogoBytes;
  bool isLoading = true;
  String? errorMessage;
  QRCodeService? qrCodeService;
  TipReceiverService? tipReceiverService;
  String _currency = "";
  double _balance = 0.0;
  TipReceiveerData? _tipReceiverData;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _loadQRCodeFromBackend();
    _loadSavedLogo();
    _fetchBalance();
    _loadTipReceiverData();
  }

  Future<void> _loadTipReceiverData() async {
    final response = await tipReceiverService?.GetMe();
    if (response != null && response.success) {
      if (mounted) {
        setState(() {
          _tipReceiverData = response.data;
        });
      }
    }
  }

  Future<void> _initializeScreen() async {
    qrCodeService = sl<QRCodeService>();
    tipReceiverService = sl<TipReceiverService>();
    _currency = await StorageService.get('Currency') ?? "";
  }

  Future<void> _loadQRCodeFromBackend() async {
    final userId = await StorageService.get('user_id');
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await qrCodeService?.getQRCode();

      if (response != null && response.success) {
        final base64Data = response.data?.qrCodeBase64;
        if (base64Data != null && base64Data.isNotEmpty) {
          final bytes = _decodeBase64(base64Data);
          if (mounted) {
            setState(() {
              qrBytes = bytes;
            });
          }
        } else {
          // Handle case where no QR code exists yet
          if (mounted) {
            setState(() {
              errorMessage = "No QR code found. Please generate one first.";
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = response?.message ?? "Failed to load QR code";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error loading QR code: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Uint8List _decodeBase64(String base64String) {
    // Remove data URI prefix if present
    final cleanBase64 =
        base64String.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '');
    return base64.decode(cleanBase64);
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final Uint8List? logoToShow = savedLogoBytes ?? widget.logoBytes;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                CustomTopBar.home(
                  profileImagePath: _tipReceiverData?.imagePath != null &&
                          _tipReceiverData!.imagePath!.isNotEmpty
                      ? "${ApiServicePath.fileServiceUrl}/${_tipReceiverData!.imagePath}"
                      : null,
                  onProfileTap: () {
                    Navigator.pushNamed(context, AppRoutes.profilePage);
                  },
                  onNotificationTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                  showNotification: _showNotifications,
                ),
                const SizedBox(height: 160),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 87, 24, 24),
                      child: Column(
                        children: [
                          _buildQrSection(languageService, logoToShow),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Grouped welcome text, available balance card, and shadow
            Positioned(
              top: 70, // Starting position for the group
              left: 0,
              right: 0,
              child: _buildWelcomeCardGroup(languageService),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          if (mounted) {
            setState(() {
              _currentBottomNavIndex = index;
            });
          }
          _handleBottomNavTap(index);
        },
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.walletScreen);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.transactions);
        break;
    }
  }

  Widget _buildWelcomeCardGroup(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Welcome text section
        _buildWelcomeSection(languageService),
        const SizedBox(height: 24), // 24px space between welcome text and card
        // Available balance card
        const AvailableBalanceCard(
          transferDate: '', // Empty since we're not showing it
          backgroundImagePath: 'assets/images/available-balance.png',
          iconPath: 'assets/icons/logo-without-text.svg',
          showTransferDate: false, // Hide the transfer date line
        ),
        const SizedBox(height: 2), // 2px space between card and shadow
        // Shadow under the card
        _buildCardShadow(),
      ],
    );
  }

  Widget _buildWelcomeSection(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _tipReceiverData != null
              ? "${languageService.getText('Welcome')} ${_tipReceiverData!.firstName ?? ''}"
              : "${languageService.getText('Welcome')}",
          textAlign: TextAlign.center,
          style: AppFonts.lgBold(context, color: AppColors.white),
        ),
        const SizedBox(height: 6),
        Text(
          languageService.getText('goodToSeeYou'),
          textAlign: TextAlign.center,
          style: AppFonts.smMedium(context, color: AppColors.white),
        ),
      ],
    );
  }

  Widget _buildCardShadow() {
    return Container(
      width: _cardWidth, // Same width as the available balance card
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(120),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          )
        ],
      ),
    );
  }

  Widget _buildQrSection(
      LanguageService languageService, Uint8List? logoToShow) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            _buildQrContainer(languageService, logoToShow),
            _buildCustomizeButton(languageService),
          ],
        ),
      ],
    );
  }

  Widget _buildShadow() {
    return Container(
      width: 265,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(120),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          )
        ],
      ),
    );
  }

  Widget _buildQrContainer(
      LanguageService languageService, Uint8List? logoToShow) {
    return Container(
      width: 338,
      height: 342,
      decoration: BoxDecoration(
        color: AppColors.gray_bg_2,
        border: Border.all(color: AppColors.border_3, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Text(
            languageService.getArabicTextWithEnglishString("MyTipMeQR"),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildQrWithLogo(logoToShow),
          const SizedBox(height: 10),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQrWithLogo(Uint8List? logoToShow) {
    if (isLoading) {
      return Container(
        width: 160,
        height: 160,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: 160,
        height: 160,
        child: Center(
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.gray_bg_2,
      ),
      child: Center(
        child: QRContent(
          isGenerating: false,
          qrImageBytes: qrBytes,
          qrDataUri: null,
          errorMessage: null,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QuickIcon(
          assetPath: "assets/icons/icon-share.svg",
          label: "Share",
          onTap: _shareQr,
        ),
        const SizedBox(width: 16),
        QuickIcon(
          assetPath: "assets/icons/icon-download2.svg",
          label: "Save",
          onTap: () async {
            await _saveQrToGallery(qrBytes, context);
          },
        ),
      ],
    );
  }

  Future<void> _shareQr() async {
    if (qrBytes == null) {
      // Show a message if QR code is not loaded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code available to share')),
      );
      return;
    }

    try {
      // Create a temporary file in the device to share the QR code image
      final tempDir = Directory.systemTemp;
      final file = await File('${tempDir.path}/MyTipMeQR.png').create();
      await file.writeAsBytes(qrBytes!);

      // Use share_plus to open the share sheet (options to share)
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my TipMe QR code!',
      );

      // show a confirmation SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing QR Code...')),
      );
    } catch (e) {
      // Show an error message if sharing fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing QR Code: $e')),
      );
    }
  }

  Future<void> _saveQrToGallery(
      Uint8List? qrBytes, BuildContext context) async {
    if (qrBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code available to save')),
      );
      return;
    }

    try {
      if (Platform.isAndroid) {
        // For Android 10+ (API 29+), gal uses MediaStore API which doesn't require permissions
        // For older versions, we only need WRITE_EXTERNAL_STORAGE (already in manifest with maxSdkVersion="28")
        bool hasPermission = true; // Default to true for modern Android
        
        // Only check storage permission for Android 9 and below (API 28 and below)
        if (await Permission.storage.isDenied) {
          final storageStatus = await Permission.storage.request();
          if (storageStatus.isDenied) {
            hasPermission = false;
          } else if (storageStatus.isPermanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Storage permission permanently denied. Please enable it in Settings.'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
            return;
          }
        }
        
        // Fallback to storage permission for older Android versions (API < 28)
        if (!hasPermission) {
          if (await Permission.storage.isGranted) {
            hasPermission = true;
          } else {
            final storageStatus = await Permission.storage.request();
            if (storageStatus.isGranted) {
              hasPermission = true;
            } else if (storageStatus.isPermanentlyDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Storage permission permanently denied. Please enable it in Settings.'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Settings',
                    onPressed: () => openAppSettings(),
                  ),
                ),
              );
              return;
            }
          }
        }
        
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied to save image. Please grant storage access in Settings.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      } else if (Platform.isIOS) {
        // iOS still requires photos permission
        if (!await Permission.photos.isGranted) {
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photos permission denied')),
            );
            return;
          }
        }
      }

      // Save the image using gal (uses MediaStore API on Android 10+, no permissions needed)
      await Gal.putImageBytes(
        qrBytes,
        name: "MyTipMeQR_${DateTime.now().millisecondsSinceEpoch}",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code saved to gallery!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving QR Code: $e'),
        ),
      );
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) uses READ_MEDIA_IMAGES
      if (await Permission.photos.isGranted) return true;

      var status = await Permission.photos.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      var status = await Permission.photos.request();
      return status.isGranted;
    }
    return false;
  }

  Widget _buildCustomizeButton(LanguageService languageService) {
    return Positioned(
      bottom: -30,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 170,
          height: 48,
          child: ElevatedButton(
            onPressed: _openCustomize,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: Text(
              languageService.getText("customizeQR"),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCustomize() async {
    final user_id = await StorageService.get('user_id');
    // ignore: use_build_context_synchronously
    await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomizeQrScreen(
          qrBytes: qrBytes,
          currentLogo: logoBytes,
          qrDataUri: null, // We're using bytes from backend
          frontendUrl: "your-frontend-url", // Replace with actual frontend URL
          tipReceiverId: user_id ?? "",
        ),
      ),
    );

    // Always refresh the QR code from backend when returning
    await _loadQRCodeFromBackend();

    // Also refresh the logo in case it was updated
    await _loadSavedLogo();
  }

  Future<void> _saveLogo(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logoBase64', base64.encode(bytes));
    if (mounted) {
      setState(() {
        savedLogoBytes = bytes;
      });
    }
  }

  Future<void> _loadSavedLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogo = prefs.getString('logoBase64');
    if (savedLogo != null) {
      try {
        if (mounted) {
          setState(() {
            logoBytes = base64.decode(savedLogo);
          });
        }
      } catch (e) {
        print('Error loading saved logo: $e');
      }
    }
  }

  Future<void> _fetchBalance() async {
    try {
      _statisticsService = sl<TipReceiverStatisticsService>();
      final response = await _statisticsService.getBalance();
      if (mounted) {
        setState(() {
          _balance = response.data["total"];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balance = 0.0;
        });
      }
    }
  }
}
