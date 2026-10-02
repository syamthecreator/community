// import 'package:community/core/theme/app_colors.dart';
// import 'package:community/core/widgets/glass.dart';
// import 'package:community/features/authentication/provider/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';

// class PhoneNumberField extends StatelessWidget {
//   final FocusNode focusNode;

//   const PhoneNumberField({super.key, required this.focusNode});

//   String? _getErrorText(BuildContext context, AuthValidationError? error) {
//     switch (error) {
//       case AuthValidationError.empty:
//         return "Enter a valid Indian mobile number";

//       case AuthValidationError.invalidLength:
//         return "Mobile number must be 10 digits";

//       case AuthValidationError.invalidNumber:
//         return "Enter a valid Indian mobile number";

//       case null:
//         return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, _) {
//         final errorText = _getErrorText(context, authProvider.validationError);
//         final hasError = errorText != null;

//         // Only this widget rebuilds when focus changes (not the whole screen).
//         return ListenableBuilder(
//           listenable: focusNode,
//           builder: (context, _) {
//             final focused = focusNode.hasFocus;

//             final borderColor = hasError
//                 ? AppColors.error
//                 : focused
//                 ? AppColors.brand
//                 : Colors.white.withValues(alpha: 0.9);

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Whole box is tappable: opens / re-opens the keyboard.
//                 GestureDetector(
//                   behavior: HitTestBehavior.opaque,
//                   onTap: () => focusAndShowKeyboard(focusNode),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 180),
//                     width: double.infinity,
//                     height: 56,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withValues(alpha: 0.78),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: borderColor,
//                         width: focused || hasError ? 1.5 : 1,
//                       ),
//                       boxShadow: focused
//                           ? [
//                               BoxShadow(
//                                 color: AppColors.brand.withValues(alpha: 0.14),
//                                 blurRadius: 14,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ]
//                           : null,
//                     ),
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 16),

//                         // Plain country code + thin divider, no chip.
//                         const Text(
//                           '+91',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w700,
//                             color: AppColors.brandDark,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Container(
//                           width: 1,
//                           height: 22,
//                           color: AppColors.brand.withValues(alpha: 0.2),
//                         ),
//                         const SizedBox(width: 12),

//                         Expanded(
//                           child: TextField(
//                             controller: authProvider.phoneController,
//                             focusNode: focusNode,
//                             keyboardType: TextInputType.number,
//                             textInputAction: TextInputAction.done,
//                             autofillHints: const [
//                               AutofillHints.telephoneNumberNational,
//                             ],
//                             inputFormatters: [
//                               FilteringTextInputFormatter.digitsOnly,
//                               LengthLimitingTextInputFormatter(10),
//                             ],
//                             onChanged: (_) => authProvider.clearError(),
//                             onSubmitted: (_) =>
//                                 authProvider.continueAuth(context),
//                             cursorColor: AppColors.brand,
//                             scrollPadding: const EdgeInsets.only(bottom: 160),
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               letterSpacing: 0.8,
//                               color: Color(0xFF222222),
//                             ),
//                             decoration: InputDecoration(
//                               hintText: "Mobile number",
//                               hintStyle: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                 letterSpacing: 0,
//                                 color: AppColors.hint,
//                               ),
//                               border: InputBorder.none,
//                               enabledBorder: InputBorder.none,
//                               focusedBorder: InputBorder.none,
//                               disabledBorder: InputBorder.none,
//                               counterText: '',
//                               isDense: true,
//                               contentPadding: EdgeInsets.zero,
//                             ),
//                           ),
//                         ),

//                         const SizedBox(width: 12),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // Inline error message
//                 AnimatedSize(
//                   duration: const Duration(milliseconds: 180),
//                   alignment: Alignment.topLeft,
//                   child: hasError
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 8, left: 4),
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
