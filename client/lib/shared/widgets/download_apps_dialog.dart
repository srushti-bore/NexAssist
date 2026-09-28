import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:it_helpdesk_client/shared/constants/app_colors.dart';
import 'package:it_helpdesk_client/shared/constants/app_constants.dart';
import 'package:it_helpdesk_client/shared/constants/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal dialog providing 1-tap download options for:
/// 1. Windows Desktop Installer (.exe)
/// 2. Android Mobile Package (.apk)
class DownloadAppsDialog extends StatefulWidget {
  const DownloadAppsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DownloadAppsDialog(),
    );
  }

  @override
  State<DownloadAppsDialog> createState() => _DownloadAppsDialogState();
}

class _DownloadAppsDialogState extends State<DownloadAppsDialog> {
  bool _isDownloadingWindows = false;
  bool _isDownloadingAndroid = false;

  Future<void> _handleDownload({
    required bool isWindows,
    required String url,
    required String filename,
  }) async {
    setState(() {
      if (isWindows) {
        _isDownloadingWindows = true;
      } else {
        _isDownloadingAndroid = true;
      }
    });

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback to backend API endpoint if relative web path fails
        final fallbackUrl = isWindows
            ? '${AppConstants.defaultApiBaseUrl}/downloads/windows'
            : '${AppConstants.defaultApiBaseUrl}/downloads/android';
        await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.slateTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Downloading $filename...',
                    style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            content: Text(
              'Failed to start download: $e',
              style: GoogleFonts.publicSans(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isWindows) {
            _isDownloadingWindows = false;
          } else {
            _isDownloadingAndroid = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AppBreakpoints.mobile;

    final dialogBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final cardBg = isDark ? AppColors.cardDark : AppColors.surfaceSecondary;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Dialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Container(
        width: isCompact ? double.infinity : 620,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tray
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.devices_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download NexAssist Apps',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Install standalone desktop & mobile native clients',
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: AppSpacing.lg),

              // Windows Desktop Card
              _AppDownloadCard(
                icon: Icons.desktop_windows_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryTint,
                platformName: 'Windows Desktop Client',
                filename: 'NexAssist-Setup.exe',
                formatBadge: '.EXE',
                fileSize: '10.7 MB',
                version: 'v1.0.0 (64-bit)',
                description: 'Full offline SLA background monitoring, native desktop notifications, and zero-latency queue operations.',
                isDownloading: _isDownloadingWindows,
                onDownload: () => _handleDownload(
                  isWindows: true,
                  url: AppConstants.windowsDownloadUrl,
                  filename: 'NexAssist-Setup.exe',
                ),
                cardBg: cardBg,
                borderColor: borderColor,
                isDark: isDark,
              ),

              const SizedBox(height: AppSpacing.md),

              // Android Mobile Card
              _AppDownloadCard(
                icon: Icons.android_rounded,
                iconColor: AppColors.slateTeal,
                iconBg: AppColors.slateTealTint,
                platformName: 'Android Mobile Application',
                filename: 'NexAssist-Android.apk',
                formatBadge: '.APK',
                fileSize: '52.2 MB',
                version: 'v1.0.0 (ARM64 & x86_64)',
                description: 'On-the-go queue management, instant push notifications, ticket updates, and direct photo attachments.',
                isDownloading: _isDownloadingAndroid,
                onDownload: () => _handleDownload(
                  isWindows: false,
                  url: AppConstants.androidDownloadUrl,
                  filename: 'NexAssist-Android.apk',
                ),
                cardBg: cardBg,
                borderColor: borderColor,
                isDark: isDark,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Quick Verification Footer
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.slateTeal),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Direct, secure binaries signed for production deployment. Both packages connect to your live NexAssist cloud backend.',
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDownloadCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String platformName;
  final String filename;
  final String formatBadge;
  final String fileSize;
  final String version;
  final String description;
  final bool isDownloading;
  final VoidCallback onDownload;
  final Color cardBg;
  final Color borderColor;
  final bool isDark;

  const _AppDownloadCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.platformName,
    required this.filename,
    required this.formatBadge,
    required this.fileSize,
    required this.version,
    required this.description,
    required this.isDownloading,
    required this.onDownload,
    required this.cardBg,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            platformName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            formatBadge,
                            style: GoogleFonts.publicSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$filename • $fileSize • $version',
                      style: GoogleFonts.publicSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isDownloading ? null : onDownload,
              icon: isDownloading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 16),
              label: Text(
                isDownloading ? 'Starting Download...' : 'Download $formatBadge ($fileSize)',
                style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
