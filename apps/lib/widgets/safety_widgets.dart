import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/safety_provider.dart';
import '../services/safety_service.dart';
import '../config/theme.dart';

/// Incognito mode indicator banner
class IncognitoIndicator extends StatelessWidget {
  const IncognitoIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SafetyProvider>(
      builder: (context, safety, child) {
        if (!safety.isIncognitoSession) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade900,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off,
                size: 16,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                'Incognito Mode - History not saved',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Network privacy indicator
class NetworkPrivacyIndicator extends StatelessWidget {
  final bool compact;

  const NetworkPrivacyIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SafetyProvider>(
      builder: (context, safety, child) {
        if (!safety.networkWarningsEnabled || safety.networkStatus == null) {
          return const SizedBox.shrink();
        }

        final status = safety.networkStatus!;

        if (compact) {
          return Tooltip(
            message: status.warning ?? status.suggestion ?? status.connectionType,
            child: Icon(
              status.icon,
              size: 18,
              color: status.indicatorColor,
            ),
          );
        }

        // Only show warning for WiFi connections
        if (status.level != NetworkPrivacyLevel.caution) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(status.icon, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.connectionType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (status.warning != null)
                      Text(
                        status.warning!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  // Dismiss for this session
                  safety.setNetworkWarningsEnabled(false);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Safety tips dialog for sensitive programs
class SafetyTipsDialog extends StatelessWidget {
  final String? category;
  final String programName;
  final VoidCallback onContinue;

  const SafetyTipsDialog({
    super.key,
    this.category,
    required this.programName,
    required this.onContinue,
  });

  static Future<void> showIfNeeded({
    required BuildContext context,
    required String? category,
    required List<String>? eligibility,
    required String programName,
    required VoidCallback onContinue,
  }) async {
    final safety = context.read<SafetyProvider>();

    if (!safety.showSafetyTips) {
      onContinue();
      return;
    }

    if (!safety.isProgramSensitive(category, eligibility)) {
      onContinue();
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => SafetyTipsDialog(
        category: category,
        programName: programName,
        onContinue: () {
          Navigator.pop(context);
          onContinue();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safety = context.read<SafetyProvider>();
    final tips = safety.getSafetyTips(category);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.shield, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Safety First')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before contacting $programName, please consider these safety tips:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          tip.icon,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              tip.description,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (value) {
                    if (value == true) {
                      safety.setShowSafetyTips(false);
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    'Don\'t show safety tips again',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('I\'m in a Safe Place'),
        ),
      ],
    );
  }
}

/// Safety mode toggle card for settings
class SafetyModeCard extends StatelessWidget {
  const SafetyModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<SafetyProvider>(
      builder: (context, safety, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: safety.isIncognitoSession
                  ? [Colors.grey.shade800, Colors.grey.shade900]
                  : [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: safety.isIncognitoSession
                  ? Colors.grey.shade700
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (safety.isIncognitoSession) {
                  await safety.endIncognitoSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incognito mode ended')),
                    );
                  }
                } else {
                  safety.startIncognitoSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incognito mode started - history won\'t be saved'),
                      ),
                    );
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: safety.isIncognitoSession
                            ? Colors.grey.shade700
                            : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        safety.isIncognitoSession
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: safety.isIncognitoSession
                            ? Colors.white
                            : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            safety.isIncognitoSession
                                ? 'Incognito Mode Active'
                                : 'Start Incognito Session',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: safety.isIncognitoSession
                                  ? Colors.white
                                  : (isDark ? AppColors.darkText : AppColors.lightText),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            safety.isIncognitoSession
                                ? 'Tap to end session and clear data'
                                : 'Browse without saving history',
                            style: TextStyle(
                              fontSize: 13,
                              color: safety.isIncognitoSession
                                  ? Colors.grey.shade400
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: safety.isIncognitoSession
                          ? Colors.grey.shade500
                          : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// PIN entry dialog for safety settings protection
class PinEntryDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool isSettingPin;
  final bool isChangingPin;

  const PinEntryDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.isSettingPin = false,
    this.isChangingPin = false,
  });

  /// Show PIN entry dialog and return true if PIN is valid
  static Future<bool> showUnlock(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinEntryDialog(
        title: 'Enter PIN',
        subtitle: 'Enter your PIN to access Safety Settings',
      ),
    );
    return result ?? false;
  }

  /// Show PIN setup dialog and return true if PIN was set successfully
  static Future<bool> showSetup(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinEntryDialog(
        title: 'Set Safety PIN',
        subtitle: 'Create a 6-8 digit PIN to protect your safety settings',
        isSettingPin: true,
      ),
    );
    return result ?? false;
  }

  /// Show PIN change dialog
  static Future<bool> showChange(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PinEntryDialog(
        title: 'Change PIN',
        subtitle: 'Enter your current PIN first',
        isChangingPin: true,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _currentPinController = TextEditingController();
  final _focusNode = FocusNode();

  String? _errorMessage;
  bool _isLoading = false;
  bool _showConfirm = false;
  bool _obscurePin = true;

  // For changing PIN
  bool _currentPinVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _currentPinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final safety = context.read<SafetyProvider>();

    if (widget.isChangingPin) {
      await _handleChangePin(safety);
    } else if (widget.isSettingPin) {
      await _handleSetPin(safety);
    } else {
      await _handleUnlock(safety);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleUnlock(SafetyProvider safety) async {
    final pin = _pinController.text;

    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter your PIN');
      return;
    }

    final success = await safety.unlockWithPin(pin);
    if (success) {
      // Reset failed attempts on successful unlock
      await safety.resetFailedPinAttempts();
      if (mounted) Navigator.pop(context, true);
    } else {
      // Record failed attempt and check if panic wipe should trigger
      final shouldWipe = await safety.recordFailedPinAttempt();

      if (shouldWipe) {
        // Execute panic wipe - this will delete all data and close the app
        await safety.executePanicWipe();
        // App should be closed by now, but just in case:
        return;
      }

      // Show remaining attempts if panic wipe is enabled
      final remainingAttempts = 3 - safety.failedPinAttempts;
      if (safety.panicWipeEnabled && remainingAttempts > 0) {
        setState(() => _errorMessage = 'Incorrect PIN ($remainingAttempts attempts remaining)');
      } else {
        setState(() => _errorMessage = 'Incorrect PIN');
      }

      _pinController.clear();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _handleSetPin(SafetyProvider safety) async {
    final pin = _pinController.text;

    if (!_showConfirm) {
      // First step: validate PIN strength
      final validation = safety.validatePinStrength(pin);
      if (!validation.isValid) {
        setState(() => _errorMessage = validation.message);
        return;
      }

      // Move to confirmation step
      setState(() {
        _showConfirm = true;
        _errorMessage = null;
      });
      _confirmPinController.clear();
      return;
    }

    // Second step: confirm PIN matches
    final confirmPin = _confirmPinController.text;
    if (pin != confirmPin) {
      setState(() => _errorMessage = 'PINs do not match');
      _confirmPinController.clear();
      return;
    }

    // Set the PIN
    final result = await safety.setPin(pin);
    if (result.success) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN protection enabled')),
        );
      }
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _handleChangePin(SafetyProvider safety) async {
    if (!_currentPinVerified) {
      // First step: verify current PIN
      final currentPin = _currentPinController.text;
      final isValid = await safety.unlockWithPin(currentPin);

      if (isValid) {
        setState(() {
          _currentPinVerified = true;
          _errorMessage = null;
        });
        _pinController.clear();
      } else {
        setState(() => _errorMessage = 'Incorrect current PIN');
        _currentPinController.clear();
        HapticFeedback.heavyImpact();
      }
      return;
    }

    // Now handle like setting a new PIN
    await _handleSetPin(safety);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null && !_showConfirm && !_currentPinVerified)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodySmall,
                ),
              ),

            // Current PIN field (for changing PIN)
            if (widget.isChangingPin && !_currentPinVerified) ...[
              TextField(
                controller: _currentPinController,
                focusNode: _focusNode,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
            ],

            // New PIN field
            if (!widget.isChangingPin || _currentPinVerified) ...[
              if (_currentPinVerified)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Now enter your new PIN (6-8 digits)',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              TextField(
                controller: _pinController,
                focusNode: widget.isChangingPin ? null : _focusNode,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 8,
                enabled: !_showConfirm,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: widget.isSettingPin || _currentPinVerified ? 'New PIN' : 'PIN',
                  counterText: widget.isSettingPin || _currentPinVerified ? '${_pinController.text.length}/8' : '',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                onChanged: widget.isSettingPin || _currentPinVerified ? (_) => setState(() {}) : null,
                onSubmitted: (_) => _handleSubmit(),
              ),
            ],

            // Confirm PIN field
            if (_showConfirm) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 8,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  counterText: '',
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // PIN requirements (when setting)
            if ((widget.isSettingPin || _currentPinVerified) && !_showConfirm) ...[
              const SizedBox(height: 16),
              Text(
                'PIN Requirements:',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '• 6-8 digits\n'
                '• No repeated digits (111111)\n'
                '• No sequential numbers (123456)\n'
                '• No common patterns (121212)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_showConfirm && !widget.isChangingPin) {
                    // Go back to PIN entry
                    setState(() {
                      _showConfirm = false;
                      _errorMessage = null;
                    });
                  } else if (_currentPinVerified && widget.isChangingPin) {
                    // Go back to current PIN entry
                    setState(() {
                      _currentPinVerified = false;
                      _showConfirm = false;
                      _errorMessage = null;
                    });
                  } else {
                    Navigator.pop(context, false);
                  }
                },
          child: Text(_showConfirm || _currentPinVerified ? 'Back' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_showConfirm ? 'Confirm' : (_currentPinVerified ? 'Set PIN' : (widget.isSettingPin ? 'Next' : 'Unlock'))),
        ),
      ],
    );
  }
}
