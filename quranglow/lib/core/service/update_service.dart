import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quranglow/core/di/core_providers.dart';
import 'package:quranglow/core/storage/local_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppUpdateService {
  AppUpdateService(this._storage);

  final LocalStorage _storage;
  static const _githubRepo = 'IbrahimElshishtawy/QuranGlow';
  static const _dismissedVersionKey = 'dismissed_update_version';

  /// checks if there is a new update available on GitHub releases
  Future<void> checkForUpdate(BuildContext context, {bool forceShow = false}) async {
    try {
      // 1. Get current package version info
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // 2. Fetch latest release from GitHub
      final url = Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuranGlow-App-Updater',
        },
      );

      if (!context.mounted) return;

      if (response.statusCode != 200) {
        if (forceShow) {
          _showSnackBar(context, 'فشل التحقق من التحديثات. يرجى المحاولة لاحقاً.');
        }
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestTag = data['tag_name'] as String? ?? '';
      final releaseName = data['name'] as String? ?? 'تحديث جديد';
      final releaseNotes = data['body'] as String? ?? 'إصلاحات وتحسينات عامة للتطبيق.';
      
      // Look for the first asset ending in .apk
      String? downloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      // If no APK asset is found, fallback to the release page HTML URL
      downloadUrl ??= data['html_url'] as String?;

      if (latestTag.isEmpty || downloadUrl == null) return;

      // 3. Compare versions
      final isUpdateAvailable = _isNewerVersion(currentVersion, latestTag);

      if (!isUpdateAvailable) {
        if (forceShow) {
          _showSnackBar(context, 'تطبيقك محدث إلى آخر إصدار بالفعل! 🎉');
        }
        return;
      }

      // 4. Check if this version was already dismissed by the user
      final dismissedVersion = _storage.getString(_dismissedVersionKey);
      if (dismissedVersion == latestTag && !forceShow) {
        // User previously dismissed this exact version, do not prompt again automatically
        return;
      }

      // 5. Show custom premium dialog
      if (context.mounted) {
        _showUpdateDialog(
          context: context,
          currentVersion: currentVersion,
          latestVersion: latestTag,
          releaseName: releaseName,
          changelog: releaseNotes,
          downloadUrl: downloadUrl,
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (forceShow && context.mounted) {
        _showSnackBar(context, 'حدث خطأ أثناء التحقق من وجود تحديثات.');
      }
    }
  }

  /// Helper to compare two semantic versions. Supports formats like "1.0.0", "v1.0.0", "1.0.0+1", "v1.0.0+2".
  bool _isNewerVersion(String currentVersion, String latestVersion) {
    // Clean strings (remove 'v' and extract before '+')
    final currentClean = currentVersion.split('+')[0].replaceAll('v', '').trim();
    final latestClean = latestVersion.split('+')[0].replaceAll('v', '').trim();

    final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latestClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = currentParts.length > latestParts.length ? currentParts.length : latestParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (currentPart > latestPart) return false;
    }

    // If version digits are identical, check the build numbers
    final currentBuild = _getBuildNumber(currentVersion);
    final latestBuild = _getBuildNumber(latestVersion);
    return latestBuild > currentBuild;
  }

  int _getBuildNumber(String version) {
    final parts = version.split('+');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'System', fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String releaseName,
    required String changelog,
    required String downloadUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Main dialog container
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'تحديث جديد متوفر! 🎉',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نسخة جديدة من تطبيق بُستان أصبحت جاهزة للتحميل.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Version badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildVersionBadge(
                              context: context,
                              label: 'الإصدار الحالي',
                              version: currentVersion.split('+')[0],
                              isActive: false,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_back_rounded, color: Colors.grey, size: 18),
                            ),
                            _buildVersionBadge(
                              context: context,
                              label: 'الإصدار الجديد',
                              version: latestVersion.replaceAll('v', '').split('+')[0],
                              isActive: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Changelog label
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'ما الجديد في هذا التحديث؟',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Scrollable Changelog box
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                changelog,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            // Dismiss Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  // Save dismissed version to shared preferences
                                  await _storage.putString(_dismissedVersionKey, latestVersion);
                                  if (context.mounted) Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  'لاحقاً',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Update Button
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary,
                                      cs.primary.withRed((cs.primary.red + 30).clamp(0, 255)),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final Uri uri = Uri.parse(downloadUrl);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } else {
                                      if (context.mounted) {
                                        _showSnackBar(context, 'تعذر فتح الرابط تلقائياً.');
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'تحديث الآن',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating animated icon at the top
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.secondaryContainer,
                            cs.primaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.surface,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        size: 38,
                        color: cs.primary,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(
                          duration: const Duration(seconds: 2),
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .shimmer(duration: const Duration(seconds: 3)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionBadge({
    required BuildContext context,
    required String label,
    required String version,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primary.withValues(alpha: 0.1)
            : cs.outlineVariant.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? cs.primary.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            version,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Riverpod Provider for [AppUpdateService]
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(ref.watch(storageProvider));
});
