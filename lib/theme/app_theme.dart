// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============ COLORS ============
  static const Color primary = Color(0xFF3F37C9);
  static const Color primaryDark = Color(0xFF1D1879);
  static const Color primaryLight = Color(0xFF5B52E8);
  
  static const Color surface = Color(0xFFF8F8FF);
  static const Color surfaceDark = Color(0xFF313638);
  
  static const Color success = Color(0xFF37C95C);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  
  static const Color textPrimary = Color(0xFF313638);
  static const Color textSecondary = Color(0xFF9EA3AE);
  static const Color textOnPrimary = Color(0xFFF8F8FF);
  
  // ============ GRADIENTS ============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============ SPACING ============
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  
  // ============ BORDER RADIUS ============
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 28.0;
  
  // ============ ELEVATION/SHADOWS ============
  static List<BoxShadow> shadow({double opacity = 0.15}) => [
    BoxShadow(
      color: Colors.black.withOpacity(opacity),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLarge({double opacity = 0.25}) => [
    BoxShadow(
      color: Colors.black.withOpacity(opacity),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
  
  // ============ TYPOGRAPHY ============
  static TextStyle get h1 => GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static TextStyle get h2 => GoogleFonts.montserrat(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.3,
  );
  
  static TextStyle get h3 => GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
  
  // ============ THEME DATA ============
  static ThemeData get theme => ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: surface,
    fontFamily: 'Lato',
    
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryLight,
      surface: surface,
      error: error,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: button,
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: Color(0xFFE7E7F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: Color(0xFFE7E7F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error),
      ),
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      color: Colors.white.withOpacity(0.08),
    ),
  );
  
  // ============ REUSABLE DECORATIONS ============
  static BoxDecoration glassMorphism({
    double opacity = 0.08,
    double borderOpacity = 0.25,
    double borderWidth = 1.5,
  }) => BoxDecoration(
    color: Colors.white.withOpacity(opacity),
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(
      color: Colors.white.withOpacity(borderOpacity),
      width: borderWidth,
    ),
    boxShadow: shadow(),
  );
  
  static BoxDecoration cardDecoration({
    Color? color,
    double? radius,
  }) => BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(radius ?? radiusL),
    boxShadow: shadow(),
  );
}

// ============ REUSABLE WIDGETS ============

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? AppTheme.surface : AppTheme.primary,
          foregroundColor: isSecondary ? AppTheme.textPrimary : AppTheme.textOnPrimary,
          elevation: isSecondary ? 0 : 2,
          side: isSecondary ? BorderSide(color: AppTheme.primary, width: 2) : null,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? opacity;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.opacity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.glassMorphism(opacity: opacity ?? 0.08),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: card,
      );
    }

    return card;
  }
}

class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final LinearGradient? gradient;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.primaryGradient,
        ),
        child: body,
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}