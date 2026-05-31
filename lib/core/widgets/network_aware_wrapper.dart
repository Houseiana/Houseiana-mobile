// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';
// import 'package:houseiana_mobile_app/core/widgets/no_internet_connection_widget.dart';
//
// class NetworkAwareWrapper extends StatefulWidget {
//   final Widget child;
//   final VoidCallback? onRetry;
//
//   const NetworkAwareWrapper({
//     super.key,
//     required this.child,
//     this.onRetry,
//   });
//
//   @override
//   State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
// }
//
// class _NetworkAwareWrapperState extends State<NetworkAwareWrapper> {
//   bool _isConnected = true;
//   StreamSubscription<InternetConnectionStatus>? _subscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkConnection();
//     _subscription = InternetConnectionChecker().onStatusChange.listen((status) {
//       if (mounted) {
//         setState(() {
//           _isConnected = status == InternetConnectionStatus.connected;
//         });
//       }
//     });
//   }
//
//   Future<void> _checkConnection() async {
//     final result = await InternetConnectionChecker().hasConnection;
//     if (mounted) {
//       setState(() {
//         _isConnected = result;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_isConnected) {
//       return NoInternetConnectionWidget(
//         onRetry: () {
//           _checkConnection();
//           widget.onRetry?.call();
//         },
//       );
//     }
//     return widget.child;
//   }
// }
