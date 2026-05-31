// import 'package:flutter/material.dart';
// import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
// import 'package:video_player/video_player.dart';
//
// /// Widget for displaying video testimonials on the home screen.
// class TestimonialsWidget extends StatefulWidget {
//   final List<Testimonial> testimonials;
//   final VoidCallback? onViewAll;
//
//   const TestimonialsWidget({
//     super.key,
//     required this.testimonials,
//     this.onViewAll,
//   });
//
//   @override
//   State<TestimonialsWidget> createState() => _TestimonialsWidgetState();
// }
//
// class _TestimonialsWidgetState extends State<TestimonialsWidget> {
//   int _currentIndex = 0;
//   final PageController _pageController = PageController();
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (widget.testimonials.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section Header
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Guest Testimonials',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.charcoal,
//                 ),
//               ),
//               if (widget.onViewAll != null)
//                 TextButton(
//                   onPressed: widget.onViewAll,
//                   child: const Text(
//                     'View All',
//                     style: TextStyle(color: AppColors.primaryColor),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 16),
//
//         // Video Carousel
//         SizedBox(
//           height: 200,
//           child: PageView.builder(
//             controller: _pageController,
//             onPageChanged: (index) {
//               setState(() {
//                 _currentIndex = index;
//               });
//             },
//             itemCount: widget.testimonials.length,
//             itemBuilder: (context, index) {
//               return _TestimonialCard(
//                 testimonial: widget.testimonials[index],
//               );
//             },
//           ),
//         ),
//
//         const SizedBox(height: 12),
//
//         // Page Indicators
//         if (widget.testimonials.length > 1)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(
//               widget.testimonials.length,
//               (index) => Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 4),
//                 width: index == _currentIndex ? 24 : 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   color: index == _currentIndex
//                       ? AppColors.primaryColor
//                       : AppColors.neutral400,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
//
// class _TestimonialCard extends StatefulWidget {
//   final Testimonial testimonial;
//
//   const _TestimonialCard({required this.testimonial});
//
//   @override
//   State<_TestimonialCard> createState() => _TestimonialCardState();
// }
//
// class _TestimonialCardState extends State<_TestimonialCard> {
//   VideoPlayerController? _controller;
//   bool _isInitialized = false;
//   bool _isPlaying = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   Future<void> _initializeVideo() async {
//     if (widget.testimonial.videoUrl == null) return;
//
//     _controller = VideoPlayerController.networkUrl(
//       Uri.parse(widget.testimonial.videoUrl!),
//     );
//
//     try {
//       await _controller!.initialize();
//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//         });
//       }
//     } catch (e) {
//       // Video failed to load - show thumbnail instead
//     }
//   }
//
//   void _togglePlayPause() {
//     if (_controller == null) return;
//
//     setState(() {
//       if (_isPlaying) {
//         _controller!.pause();
//       } else {
//         _controller!.play();
//       }
//       _isPlaying = !_isPlaying;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: AppColors.ghostWhite,
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             // Video or Thumbnail
//             if (_isInitialized && _controller != null)
//               Center(
//                 child: AspectRatio(
//                   aspectRatio: _controller!.value.aspectRatio,
//                   child: VideoPlayer(_controller!),
//                 ),
//               )
//             else if (widget.testimonial.thumbnailUrl != null)
//               Image.network(
//                 widget.testimonial.thumbnailUrl!,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => _buildPlaceholder(),
//               )
//             else
//               _buildPlaceholder(),
//
//             // Play Button Overlay
//             if (_isInitialized || widget.testimonial.videoUrl != null)
//               Center(
//                 child: GestureDetector(
//                   onTap: _isInitialized ? _togglePlayPause : null,
//                   child: Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: Colors.black.withValues(alpha: 0.6),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       _isPlaying ? Icons.pause : Icons.play_arrow,
//                       color: Colors.white,
//                       size: 36,
//                     ),
//                   ),
//                 ),
//               ),
//
//             // Guest Info Overlay
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                     colors: [
//                       Colors.black.withValues(alpha: 0.7),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     // Avatar
//                     CircleAvatar(
//                       radius: 20,
//                       backgroundImage: widget.testimonial.guestAvatarUrl != null
//                           ? NetworkImage(widget.testimonial.guestAvatarUrl!)
//                           : null,
//                       child: widget.testimonial.guestAvatarUrl == null
//                           ? const Icon(Icons.person, color: Colors.white)
//                           : null,
//                     ),
//                     const SizedBox(width: 12),
//                     // Name and Property
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.testimonial.guestName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                               fontSize: 14,
//                             ),
//                           ),
//                           Text(
//                             widget.testimonial.propertyName,
//                             style: TextStyle(
//                               color: Colors.white.withValues(alpha: 0.8),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Rating
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryColor,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(Icons.star, size: 14, color: Colors.white),
//                           const SizedBox(width: 4),
//                           Text(
//                             widget.testimonial.rating.toString(),
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlaceholder() {
//     return Container(
//       color: AppColors.ghostWhite,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.video_library_outlined,
//               size: 48,
//               color: AppColors.neutral400,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               widget.testimonial.guestName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.charcoal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// Model for a testimonial
// class Testimonial {
//   final String id;
//   final String guestName;
//   final String? guestAvatarUrl;
//   final String propertyName;
//   final double rating;
//   final String? videoUrl;
//   final String? thumbnailUrl;
//
//   const Testimonial({
//     required this.id,
//     required this.guestName,
//     this.guestAvatarUrl,
//     required this.propertyName,
//     required this.rating,
//     this.videoUrl,
//     this.thumbnailUrl,
//   });
//
//   factory Testimonial.fromJson(Map<String, dynamic> json) {
//     return Testimonial(
//       id: json['id']?.toString() ?? '',
//       guestName: json['guestName']?.toString() ?? 'Guest',
//       guestAvatarUrl: json['guestAvatarUrl']?.toString(),
//       propertyName: json['propertyName']?.toString() ?? '',
//       rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
//       videoUrl: json['videoUrl']?.toString(),
//       thumbnailUrl: json['thumbnailUrl']?.toString(),
//     );
//   }
// }
