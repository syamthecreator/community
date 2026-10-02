// import 'package:community/core/theme/app_colors.dart';
// import 'package:community/core/widgets/glass.dart';
// import 'package:community/features/authentication/provider/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class AuthContinueButton extends StatelessWidget {
//   const AuthContinueButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, _) {
//         final ready = authProvider.isPhoneReady;

//         return GlassPrimaryButton(
//           onPressed: ready ? () => authProvider.continueAuth(context) : null,
//           child: AnimatedSwitcher(
//             duration: const Duration(milliseconds: 150),
//             child: authProvider.isLoading
//                 ? const SizedBox(
//                     key: ValueKey('loader'),
//                     width: 22,
//                     height: 22,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2.4,
//                       color: Colors.white,
//                     ),
//                   )
//                 : Text("Continue", key: const ValueKey('label')),
//           ),
//         );
//       },
//     );
//   }
// }

// class AuthTerms extends StatelessWidget {
//   const AuthTerms({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       "By continuing, you agree to our Terms of Service\nand Privacy Policy",
//       textAlign: TextAlign.center,
//       style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.body),
//     );
//   }
// }

// class AuthFooter extends StatelessWidget {
//   const AuthFooter({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 24),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.support_agent_rounded,
//             size: 16,
//             color: AppColors.brandDark.withValues(alpha: 0.8),
//           ),
//           const SizedBox(width: 8),
//           Flexible(
//             child: Text(
//               "Need help? Contact your community office",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 12.5,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.brandDark.withValues(alpha: 0.8),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
