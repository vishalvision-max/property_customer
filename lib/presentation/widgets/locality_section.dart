// import 'package:flutter/material.dart';

// class LocalitySection extends StatelessWidget {
//   final List<String> selectedLocalities;
//   final ValueChanged<String> onLocalityAdded;
//   final ValueChanged<String> onLocalityRemoved;

//   const LocalitySection({
//     super.key,
//     required this.selectedLocalities,
//     required this.onLocalityAdded,
//     required this.onLocalityRemoved,
//   });

//   void _showAddLocalityDialog(BuildContext context) {
//     final controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: const Text('Add Locality', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
//           content: TextField(
//             controller: controller,
//             autofocus: true,
//             decoration: InputDecoration(
//               hintText: 'Enter sector or area name...',
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7B2FF7),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               onPressed: () {
//                 final text = controller.text.trim();
//                 if (text.isNotEmpty) {
//                   onLocalityAdded(text);
//                 }
//                 Navigator.pop(context);
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const activeColor = Color(0xFF7B2FF7);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Add more localities',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF1D2939),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: [
//             GestureDetector(
//               onTap: () => _showAddLocalityDialog(context),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: activeColor, width: 1.5),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.add, color: activeColor, size: 16),
//                     SizedBox(width: 4),
//                     Text(
//                       'Add More',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: activeColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             ...selectedLocalities.map((locality) {
//               return GestureDetector(
//                 onTap: () => onLocalityRemoved(locality),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF9F5FF),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: activeColor.withValues(alpha: 0.3)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         locality,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: activeColor,
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       const Icon(Icons.close_rounded, color: activeColor, size: 14),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           ],
//         ),
//       ],
//     );
//   }
// }
