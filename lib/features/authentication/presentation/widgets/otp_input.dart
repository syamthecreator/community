// import 'package:community/core/theme/app_colors.dart';
// import 'package:community/core/widgets/glass.dart';
// import 'package:community/features/authentication/provider/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';

// class PinInput extends StatelessWidget {
//   final FocusNode focusNode;

//   const PinInput({super.key, required this.focusNode});

//   String? _getPinErrorText(BuildContext context, AuthProvider authProvider) {
//     if (!authProvider.hasPinError) return null;
//     return "Incorrect PIN. Please try again.";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, _) {
//         final errorText = _getPinErrorText(context, authProvider);
//         final hasError = errorText != null;

//         // Rebuild on focus change so the active box highlights correctly.
//         return ListenableBuilder(
//           listenable: Listenable.merge([focusNode, authProvider.pinController]),
//           builder: (context, _) {
//             final text = authProvider.pinController.text;
//             final activeIndex = text.length.clamp(
//               0,
//               AuthProvider.pinLength - 1,
//             );

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Tapping anywhere on the boxes opens / re-opens the keyboard.
//                 GestureDetector(
//                   behavior: HitTestBehavior.opaque,
//                   onTap: () => focusAndShowKeyboard(focusNode),
//                   child: SizedBox(
//                     height: 60,
//                     child: Stack(
//                       children: [
//                         // Hidden input field
//                         Positioned.fill(
//                           child: IgnorePointer(
//                             child: Semantics(
//                               label: "NIVA PIN",
//                               textField: true,
//                               child: TextField(
//                                 controller: authProvider.pinController,
//                                 focusNode: focusNode,
//                                 keyboardType: TextInputType.number,
//                                 textInputAction: TextInputAction.done,
//                                 inputFormatters: [
//                                   FilteringTextInputFormatter.digitsOnly,
//                                   LengthLimitingTextInputFormatter(
//                                     AuthProvider.pinLength,
//                                   ),
//                                 ],
//                                 onChanged: (_) => authProvider.clearPinError(),
//                                 onSubmitted: (_) =>
//                                     authProvider.verifyPinAndNavigate(context),
//                                 showCursor: false,
//                                 enableInteractiveSelection: false,
//                                 expands: true,
//                                 maxLines: null,
//                                 style: const TextStyle(
//                                   color: Colors.transparent,
//                                 ),
//                                 decoration: const InputDecoration(
//                                   filled: false,
//                                   border: InputBorder.none,
//                                   enabledBorder: InputBorder.none,
//                                   focusedBorder: InputBorder.none,
//                                   counterText: '',
//                                   contentPadding: EdgeInsets.zero,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),

//                         // PIN display boxes
//                         Row(
//                           children: [
//                             for (
//                               var i = 0;
//                               i < AuthProvider.pinLength;
//                               i++
//                             ) ...[
//                               if (i > 0) const SizedBox(width: 10),
//                               Expanded(
//                                 child: _PinBox(
//                                   char: i < text.length ? text[i] : null,
//                                   active:
//                                       focusNode.hasFocus && i == activeIndex,
//                                   hasError: hasError,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // Error message
//                 AnimatedSize(
//                   duration: const Duration(milliseconds: 180),
//                   alignment: Alignment.topLeft,
//                   child: hasError
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 10, left: 2),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.error_outline,
//                                 size: 16,
//                                 color: AppColors.error,
//                               ),
//                               const SizedBox(width: 6),
//                               Expanded(
//                                 child: Text(
//                                   errorText,
//                                   style: const TextStyle(
//                                     fontSize: 12.5,
//                                     fontWeight: FontWeight.w500,
//                                     color: AppColors.error,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : const SizedBox(width: double.infinity),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }

// class _PinBox extends StatelessWidget {
//   const _PinBox({
//     required this.char,
//     required this.active,
//     required this.hasError,
//   });

//   final String? char;
//   final bool active;
//   final bool hasError;

//   @override
//   Widget build(BuildContext context) {
//     final filled = char != null;

//     final accent = hasError ? AppColors.error : AppColors.brand;
//     final borderColor = hasError || active || filled
//         ? accent
//         : Colors.white.withValues(alpha: 0.9);

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 150),
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: filled && !hasError
//               ? [
//                   AppColors.brand.withValues(alpha: 0.22),
//                   AppColors.brand.withValues(alpha: 0.10),
//                 ]
//               : [
//                   Colors.white.withValues(alpha: 0.85),
//                   Colors.white.withValues(alpha: 0.55),
//                 ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: borderColor,
//           width: active || hasError ? 1.8 : 1.2,
//         ),
//         boxShadow: active || hasError
//             ? [
//                 BoxShadow(
//                   color: accent.withValues(alpha: 0.25),
//                   blurRadius: 14,
//                   offset: const Offset(0, 4),
//                 ),
//               ]
//             : null,
//       ),
//       child: filled
//           ? Text(
//               char!,
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w800,
//                 color: AppColors.title,
//               ),
//             )
//           : active
//           ? Container(
//               width: 2,
//               height: 24,
//               decoration: BoxDecoration(
//                 color: AppColors.brand,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             )
//           : null,
//     );
//   }
// }
