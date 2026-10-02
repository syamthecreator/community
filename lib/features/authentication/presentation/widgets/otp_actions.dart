// import 'package:community/core/theme/app_colors.dart';
// import 'package:community/core/widgets/glass.dart';
// import 'package:community/features/authentication/provider/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class PinActions extends StatelessWidget {
//   final FocusNode focusNode;

//   const PinActions({super.key, required this.focusNode});

//   @override
//   Widget build(BuildContext context) {
//     const labelStyle = TextStyle(
//       fontSize: 13.5,
//       height: 1.4,
//       fontWeight: FontWeight.w500,
//       color: AppColors.body,
//     );

//     return Column(
//       children: [
//         const PinVerifyButton(),

//         const SizedBox(height: 16),
//         Text(
//           "Forgot your PIN?",
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontWeight: FontWeight.w700,
//             color: AppColors.brandDark,
//           ),
//         ),
//         const SizedBox(height: 6),

//         Text(
//           "Contact your community admin",
//           textAlign: TextAlign.center,
//           style: labelStyle,
//         ),
//       ],
//     );
//   }
// }

// // -----------------------------------------------------------------------------
// // Verify button
// // -----------------------------------------------------------------------------

// class PinVerifyButton extends StatelessWidget {
//   const PinVerifyButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, _) {
//         final ready = authProvider.isPinReady;

//         return GlassPrimaryButton(
//           onPressed: ready
//               ? () => authProvider.verifyPinAndNavigate(context)
//               : null,
//           child: Text("Verify & Continue"),
//         );
//       },
//     );
//   }
// }
