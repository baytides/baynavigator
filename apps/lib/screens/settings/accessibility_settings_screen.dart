import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../config/theme.dart';

/// WCAG 2.2 AAA Accessibility Settings Screen
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
      ),
      body: Consumer<AccessibilityProvider>(
        builder: (context, accessibilityProvider, child) {
          // Update system preferences on build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            accessibilityProvider.updateSystemPreferences(context);
          });

          final settings = accessibilityProvider.settings;

          return ListView(
            children: [
              // Presets Section
              _buildSection(
                context,
                title: 'Quick Presets',
                subtitle:
                    'Presets configure multiple settings at once. Individual changes will override the preset.',
                children: [
                  for (final preset in AccessibilityPreset.values)
                    _PresetTile(
                      preset: preset,
                      isSelected: settings.activePreset == preset,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        accessibilityProvider.applyPreset(preset);
                      },
                    ),
                ],
              ),

              // Vision Section
              _buildSection(
                context,
                title: 'Vision',
                children: [
                  // Text Scale
                  _SliderTile(
                    title: 'Text Size',
                    icon: Icons.text_fields,
                    value: settings.textScale,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    valueLabel: '${(settings.textScale * 100).round()}%',
                    onChanged: (value) {
                      accessibilityProvider.setTextScale(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'Bold Text',
                    icon: Icons.format_bold,
                    value: settings.boldText,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setBoldText(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'High Contrast',
                    icon: Icons.contrast,
                    value: settings.highContrastMode,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setHighContrastMode(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'Reduce Transparency',
                    icon: Icons.layers_clear,
                    value: settings.reduceTransparency,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setReduceTransparency(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'Dyslexia-Friendly Font',
                    subtitle: 'Uses OpenDyslexic font throughout the app',
                    icon: Icons.font_download,
                    value: settings.dyslexiaFont,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setDyslexiaFont(value);
                    },
                  ),
                ],
              ),

              // Motion Section
              _buildSection(
                context,
                title: 'Motion',
                subtitle:
                    'Reduces motion effects and pauses auto-playing animations for those sensitive to motion.',
                children: [
                  _SwitchTile(
                    title: 'Reduce Motion',
                    subtitle: accessibilityProvider.systemReduceMotion
                        ? 'System setting is also enabled'
                        : null,
                    icon: Icons.animation,
                    value: settings.reduceMotion,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setReduceMotion(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'Pause Animations',
                    icon: Icons.pause_circle_outline,
                    value: settings.pauseAnimations,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setPauseAnimations(value);
                    },
                  ),
                ],
              ),

              // Reading & Display Section
              _buildSection(
                context,
                title: 'Reading & Display',
                subtitle:
                    'Adjust text spacing for improved readability per WCAG 2.2 guidelines.',
                children: [
                  _SliderTile(
                    title: 'Line Height',
                    icon: Icons.format_line_spacing,
                    value: settings.lineHeightMultiplier,
                    min: 1.0,
                    max: 2.0,
                    divisions: 10,
                    valueLabel:
                        '${settings.lineHeightMultiplier.toStringAsFixed(1)}×',
                    onChanged: (value) {
                      accessibilityProvider.setLineHeightMultiplier(value);
                    },
                  ),
                  _SliderTile(
                    title: 'Letter Spacing',
                    icon: Icons.text_fields,
                    value: settings.letterSpacing,
                    min: 0.0,
                    max: 0.1,
                    divisions: 10,
                    valueLabel: settings.letterSpacing.toStringAsFixed(2),
                    onChanged: (value) {
                      accessibilityProvider.setLetterSpacing(value);
                    },
                  ),
                  _SliderTile(
                    title: 'Word Spacing',
                    icon: Icons.space_bar,
                    value: settings.wordSpacing,
                    min: 0.0,
                    max: 0.2,
                    divisions: 10,
                    valueLabel: settings.wordSpacing.toStringAsFixed(2),
                    onChanged: (value) {
                      accessibilityProvider.setWordSpacing(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'Simple Language',
                    subtitle: 'Shows simplified descriptions when available',
                    icon: Icons.chat_bubble_outline,
                    value: settings.simpleLanguageMode,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setSimpleLanguageMode(value);
                    },
                  ),
                ],
              ),

              // Interaction Section
              _buildSection(
                context,
                title: 'Interaction',
                children: [
                  _SwitchTile(
                    title: 'Larger Touch Targets',
                    subtitle: 'Minimum 48×48 point tap areas',
                    icon: Icons.touch_app,
                    value: settings.largerTouchTargets,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setLargerTouchTargets(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'Extended Timeouts',
                    subtitle: 'Doubles time allowed for timed interactions',
                    icon: Icons.timer,
                    value: settings.extendedTimeouts,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setExtendedTimeouts(value);
                    },
                  ),
                ],
              ),

              // Audio & Captions Section
              _buildSection(
                context,
                title: 'Audio & Captions',
                children: [
                  _SwitchTile(
                    title: 'Prefer Captions',
                    icon: Icons.closed_caption,
                    value: settings.preferCaptions,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setPreferCaptions(value);
                    },
                  ),
                  _SwitchTile(
                    title: 'Visual Alerts',
                    subtitle: 'Flash screen for important audio alerts',
                    icon: Icons.flash_on,
                    value: settings.visualAlerts,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      accessibilityProvider.setVisualAlerts(value);
                    },
                  ),
                ],
              ),

              // System Accessibility Section
              _buildSection(
                context,
                title: 'System Accessibility',
                subtitle:
                    'Bay Navigator respects your system accessibility settings. Additional options above provide finer control.',
                children: [
                  _InfoTile(
                    title: 'System Reduce Motion',
                    value:
                        accessibilityProvider.systemReduceMotion ? 'On' : 'Off',
                    icon: Icons.settings,
                  ),
                  _InfoTile(
                    title: 'System Bold Text',
                    value: accessibilityProvider.systemBoldText ? 'On' : 'Off',
                    icon: Icons.settings,
                  ),
                  _InfoTile(
                    title: 'System High Contrast',
                    value:
                        accessibilityProvider.systemHighContrast ? 'On' : 'Off',
                    icon: Icons.settings,
                  ),
                ],
              ),

              // Reset Section
              _buildSection(
                context,
                title: '',
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.refresh,
                      color: accessibilityProvider.hasCustomizations
                          ? AppColors.danger
                          : Theme.of(context).disabledColor,
                    ),
                    title: Text(
                      'Reset to Defaults',
                      style: TextStyle(
                        color: accessibilityProvider.hasCustomizations
                            ? AppColors.danger
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    enabled: accessibilityProvider.hasCustomizations,
                    onTap: accessibilityProvider.hasCustomizations
                        ? () {
                            _showResetConfirmation(
                                context, accessibilityProvider);
                          }
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showResetConfirmation(
    BuildContext context,
    AccessibilityProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Accessibility Settings'),
        content: const Text(
          'This will reset all accessibility settings to their default values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Accessibility settings reset to defaults'),
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Preset Tile

class _PresetTile extends StatelessWidget {
  final AccessibilityPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        preset.icon,
        color: AppColors.primary,
      ),
      title: Text(preset.displayName),
      subtitle: Text(preset.description),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: AppColors.success,
            )
          : null,
      onTap: onTap,
    );
  }
}

// MARK: - Switch Tile

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

// MARK: - Slider Tile

class _SliderTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Expanded(child: Text(title)),
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// MARK: - Info Tile

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
      ),
    );
  }
}
