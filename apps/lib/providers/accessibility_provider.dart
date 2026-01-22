import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WCAG 2.2 AAA Accessibility Settings Model
class AccessibilitySettings {
  // Vision Settings
  final double textScale;
  final bool boldText;
  final bool highContrastMode;
  final bool reduceTransparency;
  final bool dyslexiaFont;

  // Motion Settings
  final bool reduceMotion;
  final bool pauseAnimations;

  // Reading & Display Settings
  final double lineHeightMultiplier;
  final double letterSpacing;
  final double wordSpacing;
  final bool simpleLanguageMode;

  // Interaction Settings
  final bool largerTouchTargets;
  final bool extendedTimeouts;

  // Audio & Captions Settings
  final bool preferCaptions;
  final bool visualAlerts;

  // Preset
  final AccessibilityPreset? activePreset;

  const AccessibilitySettings({
    this.textScale = 1.0,
    this.boldText = false,
    this.highContrastMode = false,
    this.reduceTransparency = false,
    this.dyslexiaFont = false,
    this.reduceMotion = false,
    this.pauseAnimations = false,
    this.lineHeightMultiplier = 1.5,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.simpleLanguageMode = false,
    this.largerTouchTargets = false,
    this.extendedTimeouts = false,
    this.preferCaptions = false,
    this.visualAlerts = false,
    this.activePreset,
  });

  static const AccessibilitySettings defaultSettings = AccessibilitySettings();

  bool get isDefault =>
      textScale == 1.0 &&
      boldText == false &&
      highContrastMode == false &&
      reduceTransparency == false &&
      dyslexiaFont == false &&
      reduceMotion == false &&
      pauseAnimations == false &&
      lineHeightMultiplier == 1.5 &&
      letterSpacing == 0.0 &&
      wordSpacing == 0.0 &&
      simpleLanguageMode == false &&
      largerTouchTargets == false &&
      extendedTimeouts == false &&
      preferCaptions == false &&
      visualAlerts == false;

  AccessibilitySettings copyWith({
    double? textScale,
    bool? boldText,
    bool? highContrastMode,
    bool? reduceTransparency,
    bool? dyslexiaFont,
    bool? reduceMotion,
    bool? pauseAnimations,
    double? lineHeightMultiplier,
    double? letterSpacing,
    double? wordSpacing,
    bool? simpleLanguageMode,
    bool? largerTouchTargets,
    bool? extendedTimeouts,
    bool? preferCaptions,
    bool? visualAlerts,
    AccessibilityPreset? activePreset,
    bool clearPreset = false,
  }) {
    return AccessibilitySettings(
      textScale: textScale ?? this.textScale,
      boldText: boldText ?? this.boldText,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      dyslexiaFont: dyslexiaFont ?? this.dyslexiaFont,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      pauseAnimations: pauseAnimations ?? this.pauseAnimations,
      lineHeightMultiplier: lineHeightMultiplier ?? this.lineHeightMultiplier,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      simpleLanguageMode: simpleLanguageMode ?? this.simpleLanguageMode,
      largerTouchTargets: largerTouchTargets ?? this.largerTouchTargets,
      extendedTimeouts: extendedTimeouts ?? this.extendedTimeouts,
      preferCaptions: preferCaptions ?? this.preferCaptions,
      visualAlerts: visualAlerts ?? this.visualAlerts,
      activePreset: clearPreset ? null : (activePreset ?? this.activePreset),
    );
  }

  Map<String, dynamic> toJson() => {
        'textScale': textScale,
        'boldText': boldText,
        'highContrastMode': highContrastMode,
        'reduceTransparency': reduceTransparency,
        'dyslexiaFont': dyslexiaFont,
        'reduceMotion': reduceMotion,
        'pauseAnimations': pauseAnimations,
        'lineHeightMultiplier': lineHeightMultiplier,
        'letterSpacing': letterSpacing,
        'wordSpacing': wordSpacing,
        'simpleLanguageMode': simpleLanguageMode,
        'largerTouchTargets': largerTouchTargets,
        'extendedTimeouts': extendedTimeouts,
        'preferCaptions': preferCaptions,
        'visualAlerts': visualAlerts,
        'activePreset': activePreset?.name,
      };

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      boldText: json['boldText'] as bool? ?? false,
      highContrastMode: json['highContrastMode'] as bool? ?? false,
      reduceTransparency: json['reduceTransparency'] as bool? ?? false,
      dyslexiaFont: json['dyslexiaFont'] as bool? ?? false,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      pauseAnimations: json['pauseAnimations'] as bool? ?? false,
      lineHeightMultiplier:
          (json['lineHeightMultiplier'] as num?)?.toDouble() ?? 1.5,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      wordSpacing: (json['wordSpacing'] as num?)?.toDouble() ?? 0.0,
      simpleLanguageMode: json['simpleLanguageMode'] as bool? ?? false,
      largerTouchTargets: json['largerTouchTargets'] as bool? ?? false,
      extendedTimeouts: json['extendedTimeouts'] as bool? ?? false,
      preferCaptions: json['preferCaptions'] as bool? ?? false,
      visualAlerts: json['visualAlerts'] as bool? ?? false,
      activePreset: json['activePreset'] != null
          ? AccessibilityPreset.values.firstWhere(
              (e) => e.name == json['activePreset'],
              orElse: () => AccessibilityPreset.values.first,
            )
          : null,
    );
  }

  /// Get scaled font size
  double scaledFontSize(double baseSize) => baseSize * textScale;

  /// Get minimum touch target size
  double get minimumTouchTargetSize => largerTouchTargets ? 48 : 44;

  /// Get timeout multiplier
  double get timeoutMultiplier => extendedTimeouts ? 2.0 : 1.0;

  /// Get animation duration (returns Duration.zero if motion reduced)
  Duration animationDuration(Duration normalDuration) {
    if (reduceMotion || pauseAnimations) {
      return Duration.zero;
    }
    return normalDuration;
  }

  /// Apply text settings to a TextStyle
  TextStyle applyTo(TextStyle style) {
    return style.copyWith(
      height: lineHeightMultiplier,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      fontWeight: boldText ? FontWeight.bold : style.fontWeight,
    );
  }
}

/// Pre-configured accessibility profiles
enum AccessibilityPreset {
  lowVision,
  motor,
  cognitive,
}

extension AccessibilityPresetExtension on AccessibilityPreset {
  String get displayName {
    switch (this) {
      case AccessibilityPreset.lowVision:
        return 'Low Vision';
      case AccessibilityPreset.motor:
        return 'Motor Accessibility';
      case AccessibilityPreset.cognitive:
        return 'Cognitive / Reading';
    }
  }

  String get description {
    switch (this) {
      case AccessibilityPreset.lowVision:
        return 'Larger text, high contrast, and bold fonts for easier viewing';
      case AccessibilityPreset.motor:
        return 'Larger touch targets, extended timeouts, and reduced motion';
      case AccessibilityPreset.cognitive:
        return 'Simple language, increased spacing, and dyslexia-friendly font';
    }
  }

  IconData get icon {
    switch (this) {
      case AccessibilityPreset.lowVision:
        return Icons.visibility;
      case AccessibilityPreset.motor:
        return Icons.touch_app;
      case AccessibilityPreset.cognitive:
        return Icons.psychology;
    }
  }

  AccessibilitySettings get settings {
    switch (this) {
      case AccessibilityPreset.lowVision:
        return AccessibilitySettings(
          textScale: 1.4,
          boldText: true,
          highContrastMode: true,
          reduceTransparency: true,
          dyslexiaFont: false,
          reduceMotion: false,
          pauseAnimations: false,
          lineHeightMultiplier: 1.6,
          letterSpacing: 0.02,
          wordSpacing: 0.05,
          simpleLanguageMode: false,
          largerTouchTargets: true,
          extendedTimeouts: false,
          preferCaptions: true,
          visualAlerts: true,
          activePreset: AccessibilityPreset.lowVision,
        );
      case AccessibilityPreset.motor:
        return AccessibilitySettings(
          textScale: 1.1,
          boldText: false,
          highContrastMode: false,
          reduceTransparency: false,
          dyslexiaFont: false,
          reduceMotion: true,
          pauseAnimations: true,
          lineHeightMultiplier: 1.5,
          letterSpacing: 0.0,
          wordSpacing: 0.0,
          simpleLanguageMode: false,
          largerTouchTargets: true,
          extendedTimeouts: true,
          preferCaptions: false,
          visualAlerts: true,
          activePreset: AccessibilityPreset.motor,
        );
      case AccessibilityPreset.cognitive:
        return AccessibilitySettings(
          textScale: 1.2,
          boldText: false,
          highContrastMode: false,
          reduceTransparency: true,
          dyslexiaFont: true,
          reduceMotion: true,
          pauseAnimations: true,
          lineHeightMultiplier: 1.8,
          letterSpacing: 0.05,
          wordSpacing: 0.1,
          simpleLanguageMode: true,
          largerTouchTargets: false,
          extendedTimeouts: true,
          preferCaptions: true,
          visualAlerts: false,
          activePreset: AccessibilityPreset.cognitive,
        );
    }
  }
}

/// Provider for managing WCAG 2.2 AAA accessibility settings
class AccessibilityProvider extends ChangeNotifier {
  static const String _storageKey = 'baynavigator:accessibility_settings';

  AccessibilitySettings _settings = AccessibilitySettings.defaultSettings;
  bool _initialized = false;

  // System preferences
  bool _systemReduceMotion = false;
  bool _systemBoldText = false;
  bool _systemHighContrast = false;

  AccessibilitySettings get settings => _settings;
  bool get initialized => _initialized;

  // System preference getters
  bool get systemReduceMotion => _systemReduceMotion;
  bool get systemBoldText => _systemBoldText;
  bool get systemHighContrast => _systemHighContrast;

  // Effective values (app OR system)
  bool get effectiveReduceMotion =>
      _settings.reduceMotion || _systemReduceMotion;
  bool get effectiveBoldText => _settings.boldText || _systemBoldText;
  bool get effectiveHighContrast =>
      _settings.highContrastMode || _systemHighContrast;

  bool get hasCustomizations => !_settings.isDefault;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _settings = AccessibilitySettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading accessibility settings: $e');
    }

    _initialized = true;
    notifyListeners();
  }

  /// Update system preferences from MediaQuery
  void updateSystemPreferences(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _systemReduceMotion = mediaQuery.disableAnimations;
    _systemBoldText = mediaQuery.boldText;
    _systemHighContrast = mediaQuery.highContrast;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('Error saving accessibility settings: $e');
    }
  }

  // MARK: - Presets

  Future<void> applyPreset(AccessibilityPreset preset) async {
    _settings = preset.settings;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> clearPreset() async {
    _settings = AccessibilitySettings.defaultSettings;
    notifyListeners();
    await _saveSettings();
  }

  // MARK: - Individual Settings

  Future<void> setTextScale(double scale) async {
    _settings = _settings.copyWith(
      textScale: scale.clamp(0.8, 2.0),
      clearPreset: true,
    );
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setBoldText(bool enabled) async {
    _settings = _settings.copyWith(boldText: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setHighContrastMode(bool enabled) async {
    _settings =
        _settings.copyWith(highContrastMode: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setReduceTransparency(bool enabled) async {
    _settings =
        _settings.copyWith(reduceTransparency: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setDyslexiaFont(bool enabled) async {
    _settings = _settings.copyWith(dyslexiaFont: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setReduceMotion(bool enabled) async {
    _settings = _settings.copyWith(reduceMotion: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setPauseAnimations(bool enabled) async {
    _settings = _settings.copyWith(pauseAnimations: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setLineHeightMultiplier(double multiplier) async {
    _settings = _settings.copyWith(
      lineHeightMultiplier: multiplier.clamp(1.0, 2.0),
      clearPreset: true,
    );
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setLetterSpacing(double spacing) async {
    _settings = _settings.copyWith(
      letterSpacing: spacing.clamp(0.0, 0.1),
      clearPreset: true,
    );
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setWordSpacing(double spacing) async {
    _settings = _settings.copyWith(
      wordSpacing: spacing.clamp(0.0, 0.2),
      clearPreset: true,
    );
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setSimpleLanguageMode(bool enabled) async {
    _settings =
        _settings.copyWith(simpleLanguageMode: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setLargerTouchTargets(bool enabled) async {
    _settings =
        _settings.copyWith(largerTouchTargets: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setExtendedTimeouts(bool enabled) async {
    _settings =
        _settings.copyWith(extendedTimeouts: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setPreferCaptions(bool enabled) async {
    _settings = _settings.copyWith(preferCaptions: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setVisualAlerts(bool enabled) async {
    _settings = _settings.copyWith(visualAlerts: enabled, clearPreset: true);
    notifyListeners();
    await _saveSettings();
  }

  // MARK: - Reset

  Future<void> resetToDefaults() async {
    _settings = AccessibilitySettings.defaultSettings;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error resetting accessibility settings: $e');
    }
  }
}

/// High contrast color palette for WCAG 2.2 AAA compliance (10:1+ contrast)
class HighContrastColors {
  static const Color text = Color(0xFF000000);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color primary = Color(0xFF004040);
  static const Color primaryOnDark = Color(0xFF80FFFF);
  static const Color link = Color(0xFF0000CC);
  static const Color linkOnDark = Color(0xFF99CCFF);
  static const Color focus = Color(0xFF000000);
  static const Color focusOnDark = Color(0xFFFFFF00);
  static const Color error = Color(0xFFCC0000);
  static const Color errorOnDark = Color(0xFFFF6666);
  static const Color success = Color(0xFF006600);
  static const Color successOnDark = Color(0xFF66FF66);
}
