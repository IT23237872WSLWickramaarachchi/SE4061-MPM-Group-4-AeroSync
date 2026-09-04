import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class SavePresetModal extends StatefulWidget {
  const SavePresetModal({super.key});

  @override
  State<SavePresetModal> createState() => _SavePresetModalState();
}

class _SavePresetModalState extends State<SavePresetModal> {
  late TextEditingController _nameController;
  late TextEditingController _gameIdController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AeroSyncStateProvider>();
    _nameController = TextEditingController(text: state.presetSaveName);
    _gameIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();
    if (!state.isSaveModalOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop overlay
        GestureDetector(
          onTap: () => state.closeSaveModal(),
          child: Container(
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
        // Modal Dialog Box
        Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AeroSyncTheme.panelBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AeroSyncTheme.borderColor, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Close Icon
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AeroSyncTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cyclone, size: 16, color: AeroSyncTheme.darkBackground),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Save Preset',
                      style: TextStyle(
                        color: AeroSyncTheme.textMain,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: AeroSyncTheme.fontHeadline,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => state.closeSaveModal(),
                      icon: const Icon(Icons.close, size: 18, color: AeroSyncTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Preset Name',
                  style: TextStyle(
                    color: AeroSyncTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: AeroSyncTheme.fontHeadline,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10151C),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AeroSyncTheme.borderColor),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      color: AeroSyncTheme.textMain,
                      fontSize: 13,
                      fontFamily: AeroSyncTheme.fontTechnical,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Linked Game ID (Optional)',
                  style: TextStyle(
                    color: AeroSyncTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: AeroSyncTheme.fontHeadline,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10151C),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AeroSyncTheme.borderColor),
                  ),
                  child: TextField(
                    controller: _gameIdController,
                    style: const TextStyle(
                      color: AeroSyncTheme.textMain,
                      fontSize: 13,
                      fontFamily: AeroSyncTheme.fontTechnical,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g., EagleFlight01',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => state.closeSaveModal(),
                      style: TextButton.styleFrom(
                        foregroundColor: AeroSyncTheme.textMain,
                        backgroundColor: const Color(0xFF222B38),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13, fontFamily: AeroSyncTheme.fontHeadline)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          state.saveCurrentPreset(
                            _nameController.text.trim(),
                            linkedGameId: _gameIdController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AeroSyncTheme.primaryTeal,
                        foregroundColor: AeroSyncTheme.darkBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AeroSyncTheme.fontHeadline)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
