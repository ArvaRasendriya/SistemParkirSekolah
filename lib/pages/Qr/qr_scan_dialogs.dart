import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      title: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: AppTheme.spaceS),
          Text('Gagal', style: AppTheme.h3.copyWith(color: AppTheme.error)),
        ],
      ),
      content: Text(message, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

Widget buildLoadingOverlay() => Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceXL),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: AppTheme.spaceM),
              Text('Memproses...', style: AppTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
