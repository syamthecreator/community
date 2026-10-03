import 'dart:async';

import 'package:community/app/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AuthValidationError { empty, invalidLength, invalidNumber, notRegistered }

// NEW
enum AuthFlowStep { phone, pin }

class AuthProvider extends ChangeNotifier {
  static const int pinLength = 4;
  static const int maxPinAttempts = 5;
  static const int lockoutSeconds = 30;

  // Demo PIN. Replace with the admin-issued PIN check from your API.
  static const String mockPin = '1234';

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  // Flow state (NEW)
  AuthFlowStep _step = AuthFlowStep.phone;
  bool _isPhoneVerified = false;

  // Phone state
  AuthValidationError? _validationError;
  bool _isLoading = false;
  int _phoneErrorTick = 0;

  // PIN state
  bool _pinWrong = false;
  bool _isVerifying = false;
  bool _pinVerified = false;
  int _pinAttempts = 0;
  int _pinErrorTick = 0;
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;

  AuthProvider() {
    phoneController.addListener(_onPhoneChanged);
    pinController.addListener(_onPinChanged);
  }

  // ---------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------

  AuthFlowStep get step => _step; // NEW
  bool get isPhoneVerified => _isPhoneVerified; // NEW

  AuthValidationError? get validationError => _validationError;
  bool get isLoading => _isLoading;
  int get phoneErrorTick => _phoneErrorTick;
  String get phoneNumber => phoneController.text.trim();
  bool get isPhoneReady => phoneNumber.length == 10 && !_isLoading;

  bool get hasPinError => _pinWrong;
  bool get isVerifying => _isVerifying;
  bool get isPinVerified => _pinVerified;
  bool get isLocked => _lockSecondsLeft > 0;
  int get pinErrorTick => _pinErrorTick;
  int get attemptsLeft => maxPinAttempts - _pinAttempts;
  bool get isPinReady =>
      pinController.text.length == pinLength && !_isVerifying && !isLocked;

  /// "0:27" style countdown while locked.
  String get lockCountdown {
    final m = _lockSecondsLeft ~/ 60;
    final s = (_lockSecondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------

  void _onPhoneChanged() {
    _validationError = null;
    notifyListeners();
  }

  bool validatePhone() {
    final phone = phoneNumber;

    if (phone.isEmpty) {
      _validationError = AuthValidationError.empty;
    } else if (phone.length != 10) {
      _validationError = AuthValidationError.invalidLength;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _validationError = AuthValidationError.invalidNumber;
    } else {
      _validationError = null;
    }

    if (_validationError != null) _phoneErrorTick++;
    notifyListeners();
    return _validationError == null;
  }

  void clearError() {
    if (_validationError == null) return;
    _validationError = null;
    notifyListeners();
  }

  // Replace with a real lookup: is this number registered by an admin?
  Future<bool> _isRegistered(String phone) async => true;

  // CHANGED: no Navigator.push. Shows loader -> tick -> swaps to PIN step.
  Future<void> continueAuth(BuildContext context) async {
    if (_isLoading || _isPhoneVerified) return;

    FocusScope.of(context).unfocus();
    if (!validatePhone()) return;

    _isLoading = true;
    notifyListeners();

    try {
      final registered = await _isRegistered(phoneNumber);

      if (!registered) {
        _validationError = AuthValidationError.notRegistered;
        _phoneErrorTick++;
        return; // finally clears the loader
      }

      // Registered: loader -> tick on the button.
      HapticFeedback.lightImpact();
      _isLoading = false;
      _isPhoneVerified = true;
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (!context.mounted) {
        _isPhoneVerified = false;
        return;
      }

      // Swap the content in place. No route change.
      _isPhoneVerified = false;
      _step = AuthFlowStep.pin;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: used by the "Change" chip, back button and system back.
  void backToPhone() {
    pinController.clear(); // fires the listener, so set flags after this
    _pinWrong = false;
    _isVerifying = false;
    _pinVerified = false;
    _isPhoneVerified = false;
    _step = AuthFlowStep.phone;
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // PIN
  // ---------------------------------------------------------------

  void _onPinChanged() {
    _pinWrong = false;
    notifyListeners();
  }

  /// Call when the PIN step opens. Keeps an active lockout running.
  void initializePin() {
    pinController.clear();
    _pinWrong = false;
    _isVerifying = false;
    _pinVerified = false;
    notifyListeners();
  }

  Future<void> verifyPinAndNavigate(BuildContext context) async {
    if (!isPinReady) return;

    final code = pinController.text.trim();

    _isVerifying = true;
    notifyListeners();

    // Replace with the real PIN check.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (code != mockPin) {
      _handleWrongPin();
      return;
    }

    HapticFeedback.lightImpact();
    _pinVerified = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home,
      (route) => false,
    );
  }

  void _handleWrongPin() {
    HapticFeedback.mediumImpact();
    pinController.clear(); // fires the listener, so set flags after this
    _isVerifying = false;
    _pinAttempts++;
    _pinErrorTick++;
    _pinWrong = true;

    if (_pinAttempts >= maxPinAttempts) _startLockout();
    notifyListeners();
  }

  void _startLockout() {
    _pinAttempts = 0;
    _pinWrong = false;
    _lockSecondsLeft = lockoutSeconds;

    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _lockSecondsLeft--;
      if (_lockSecondsLeft <= 0) {
        _lockSecondsLeft = 0;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    phoneController.removeListener(_onPhoneChanged);
    pinController.removeListener(_onPinChanged);
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }
}
