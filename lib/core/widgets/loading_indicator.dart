import 'package:flutter/material.dart';
import 'package:pack_vault/core/constants/app_constants.dart';

class LoadingIndicator extends StatefulWidget {
  final String message;
  const LoadingIndicator({super.key, this.message = 'Loading...'});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: const Icon(
              Icons.sports_soccer,
              size: 48,
              color: AppColors.pitchGreenGlow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
