import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/preset_model.dart';
import '../providers/aerosync_state_provider.dart';
import '../theme/aerosync_theme.dart';

class PresetLibraryView extends StatefulWidget {
  const PresetLibraryView({super.key});

  @override
  State<PresetLibraryView> createState() => _PresetLibraryViewState();
}

class _PresetLibraryViewState extends State<PresetLibraryView> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AeroSyncStateProvider>();
    final filteredPresets = state.presets
        .where((p) => p.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    final selectedPreset = state.presets.firstWhere(
      (p) => p.isSelected,
      orElse: () => state.presets.first,
    );

    return Container(
      padding: const EdgeInsets.all(32),
      color: AeroSyncTheme.darkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon + Title & Subtitle
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AeroSyncTheme.panelBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cyclone, size: 20, color: AeroSyncTheme.primaryTeal),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preset Library',
                        style: TextStyle(
                          color: AeroSyncTheme.textMain,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: AeroSyncTheme.fontHeadline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage and load saved physical wind configurations.',
                        style: TextStyle(
                          color: AeroSyncTheme.textMuted.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontFamily: AeroSyncTheme.fontHeadline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Search Bar Input
              Container(
                width: 240,
                height: 38,
                decoration: BoxDecoration(
                  color: AeroSyncTheme.panelBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AeroSyncTheme.borderColor),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  style: const TextStyle(color: AeroSyncTheme.textMain, fontSize: 13, fontFamily: AeroSyncTheme.fontHeadline),
                  decoration: const InputDecoration(
                    hintText: 'Search presets...',
                    hintStyle: TextStyle(color: AeroSyncTheme.textDim, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 16, color: AeroSyncTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // + New Preset Button
              ElevatedButton.icon(
                onPressed: () => state.openSaveModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AeroSyncTheme.panelBackground,
                  foregroundColor: AeroSyncTheme.textMain,
                  side: const BorderSide(color: AeroSyncTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 16, color: AeroSyncTheme.primaryTeal),
                label: const Text('New Preset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: AeroSyncTheme.fontHeadline)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Presets Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                childAspectRatio: 2.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredPresets.length,
              itemBuilder: (context, index) {
                final preset = filteredPresets[index];
                return _buildPresetCard(context, preset, state);
              },
            ),
          ),
          // Bottom Actions Row: Load Selected Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  state.selectPreset(selectedPreset.id);
                  state.setActiveRailIndex(0); // Return to editor canvas
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AeroSyncTheme.primaryTeal,
                  foregroundColor: AeroSyncTheme.darkBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(
                  'Load Selected (${selectedPreset.title})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: AeroSyncTheme.fontHeadline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard(BuildContext context, WindPreset preset, AeroSyncStateProvider state) {
    final bool isSelected = preset.isSelected;

    return InkWell(
      onTap: () => state.selectPreset(preset.id),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AeroSyncTheme.cardSelectedBackground : AeroSyncTheme.panelBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AeroSyncTheme.primaryTeal : AeroSyncTheme.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    preset.title,
                    style: TextStyle(
                      color: isSelected ? AeroSyncTheme.primaryTeal : AeroSyncTheme.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: AeroSyncTheme.fontHeadline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AeroSyncTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: AeroSyncTheme.darkBackground),
                  )
                else
                  const Icon(Icons.more_vert, size: 16, color: AeroSyncTheme.textMuted),
              ],
            ),
            Text(
              'Modified: ${preset.modifiedTime}',
              style: const TextStyle(
                color: AeroSyncTheme.textMuted,
                fontSize: 11,
                fontFamily: AeroSyncTheme.fontTechnical,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
