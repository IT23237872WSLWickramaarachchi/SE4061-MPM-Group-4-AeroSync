import 'package:flutter/material.dart';
import '../theme/aerosync_theme.dart';

class AeroSyncFooter extends StatelessWidget {
  const AeroSyncFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AeroSyncTheme.darkBackground,
        border: Border(
          top: BorderSide(color: AeroSyncTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2024 AeroSync Industrial Systems',
            style: TextStyle(
              color: AeroSyncTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              _buildFooterLink('Documentation'),
              const SizedBox(width: 16),
              _buildFooterLink('Support'),
              const SizedBox(width: 16),
              _buildFooterLink('Changelog'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: const TextStyle(
          color: AeroSyncTheme.textMuted,
          fontSize: 11,
        ),
      ),
    );
  }
}
