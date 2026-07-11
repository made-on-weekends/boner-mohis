package com.example.bonermohis.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

import androidx.compose.ui.text.googlefonts.GoogleFont
import androidx.compose.ui.text.googlefonts.Font
import com.example.bonermohis.R

val fontProvider = GoogleFont.Provider(
    providerAuthority = "com.google.android.gms.fonts",
    providerPackage = "com.google.android.gms",
    certificates = R.array.com_google_android_gms_fonts_certs
)

val SpaceGroteskFont = GoogleFont("Space Grotesk")
val SpaceGroteskFontFamily = FontFamily(
    Font(googleFont = SpaceGroteskFont, fontProvider = fontProvider, weight = FontWeight.Medium),
    Font(googleFont = SpaceGroteskFont, fontProvider = fontProvider, weight = FontWeight.Normal),
    Font(googleFont = SpaceGroteskFont, fontProvider = fontProvider, weight = FontWeight.Bold)
)

val DmSansFont = GoogleFont("DM Sans")
val DmSansFontFamily = FontFamily(
    Font(googleFont = DmSansFont, fontProvider = fontProvider, weight = FontWeight.Normal),
    Font(googleFont = DmSansFont, fontProvider = fontProvider, weight = FontWeight.Medium),
    Font(googleFont = DmSansFont, fontProvider = fontProvider, weight = FontWeight.Bold)
)

val DmMonoFont = GoogleFont("DM Mono")
val DmMonoFontFamily = FontFamily(
    Font(googleFont = DmMonoFont, fontProvider = fontProvider, weight = FontWeight.Normal),
    Font(googleFont = DmMonoFont, fontProvider = fontProvider, weight = FontWeight.Medium)
)

val Typography = Typography(
    displayLarge = TextStyle(
        fontFamily = SpaceGroteskFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 48.sp,
        lineHeight = 56.sp
    ),
    headlineMedium = TextStyle(
        fontFamily = SpaceGroteskFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 24.sp,
        lineHeight = 32.sp
    ),
    titleLarge = TextStyle(
        fontFamily = SpaceGroteskFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 20.sp,
        lineHeight = 28.sp
    ),
    bodyLarge = TextStyle(
        fontFamily = DmSansFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = DmSansFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp
    ),
    labelMedium = TextStyle(
        fontFamily = DmSansFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    ),
    labelSmall = TextStyle(
        fontFamily = DmMonoFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 11.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    )
)
