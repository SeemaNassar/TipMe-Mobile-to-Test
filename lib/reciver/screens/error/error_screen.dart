import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../utils/colors.dart';
import '../../../utils/app_font.dart';
import '../../../data/services/language_service.dart';

class ErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final String? errorDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final bool showRetry;
  final bool showGoBack;

  const ErrorScreen({
    Key? key,
    this.title,
    this.message,
    this.errorDetails,
    this.onRetry,
    this.onGoBack,
    this.showRetry = true,
    this.showGoBack = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: showGoBack
            ? IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/arrow-left.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: onGoBack ?? () => Navigator.of(context).pop(),
              )
            : null,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 80 : 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Error Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 40,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Title
                    Text(
                      title ?? 'Something went wrong',
                      style: AppFonts.h3(context, color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Error Message
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 400 : screenSize.width - 48,
                      ),
                      child: Text(
                        message ?? 'An unexpected error occurred. Please try again.',
                        style: AppFonts.mdMedium(context,
                            color: AppColors.white.withOpacity(0.9)),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Error Details (Expandable)
                    if (errorDetails != null && errorDetails!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildErrorDetailsSection(context, errorDetails!),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  if (showRetry) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onRetry ?? () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(48),
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: AppFonts.mdBold(context, color: AppColors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (showGoBack) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: onGoBack ?? () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.white, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(48),
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: AppFonts.mdBold(context, color: AppColors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDetailsSection(BuildContext context, String details) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          title: Text(
            'Technical Details',
            style: AppFonts.smBold(context, color: AppColors.white),
          ),
          iconColor: AppColors.white,
          collapsedIconColor: AppColors.white,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200, // Fixed height for scrollable area
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        details,
                        style: AppFonts.xsMedium(context,
                            color: AppColors.white.withOpacity(0.8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: details));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error details copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white,
                            side: const BorderSide(color: AppColors.white, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
