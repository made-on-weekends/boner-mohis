import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/filament_theme.dart';

Future<void> launchDonationUrl() async {
  final uri = Uri.parse(
    'https://asifiqbal.rocks/donation?utm_source=boner_mohis&utm_medium=android_app&utm_campaign=app_ui&ref=boner-mohis-android',
  );
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    debugPrint('Could not launch donation URL with externalApplication: $e');
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e2) {
      debugPrint('Could not launch donation URL with platformDefault: $e2');
    }
  }
}

class DonationCard extends StatelessWidget {
  final VoidCallback? onTap;
  const DonationCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;
    final cardBg =
        isDark ? FilamentColors.darkCard : FilamentColors.cardBgLight;
    final border =
        isDark ? FilamentColors.darkBorder : FilamentColors.borderLight;

    final emberColor =
        isDark ? FilamentColors.emberOrangeDark : FilamentColors.emberOrange;

    final tapHandler = onTap ?? launchDonationUrl;

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapHandler,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Text(
                '☕',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enjoying BonerMohis?',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Support BonerMohis development',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: tapHandler,
                style: ElevatedButton.styleFrom(
                  backgroundColor: emberColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Donate ☕',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
