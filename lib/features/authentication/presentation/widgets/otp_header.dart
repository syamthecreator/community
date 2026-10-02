// import 'package:community/core/constants/asset_constants.dart';
// import 'package:community/core/theme/app_colors.dart';
// import 'package:flutter/material.dart';

// class PinHeader extends StatelessWidget {
//   final String phoneNumber;

//   const PinHeader({super.key, required this.phoneNumber});

//   @override
//   Widget build(BuildContext context) {

//     return Column(
//       children: [
//         Image.asset(AssetConstants.nivaLogo, width: 120, fit: BoxFit.contain),

//         const SizedBox(height: 28),

//         Text(
//           "Enter your NIVA PIN",
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 27,
//             fontWeight: FontWeight.w800,
//             letterSpacing: -0.4,
//             color: AppColors.title,
//           ),
//         ),

//         const SizedBox(height: 10),

//         Text(
//           "Enter the 4-digit PIN\n provided by your community admin",
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 14,
//             height: 1.5,
//             fontWeight: FontWeight.w500,
//             color: AppColors.body,
//           ),
//         ),

//         const SizedBox(height: 4),

//         TextButton(
//           onPressed: () => Navigator.maybePop(context),
//           style: TextButton.styleFrom(
//             foregroundColor: AppColors.brand,
//             visualDensity: VisualDensity.compact,
//           ),
//           child: Text(
//             "Wrong number?",
//             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
//           ),
//         ),
//       ],
//     );
//   }
// }
