import 'dart:async';

import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

/// "BotRoad réfléchit..." avec points animés . .. ... — pas de spinner.
class ThinkingDots extends StatefulWidget {
  final String label;

  const ThinkingDots({super.key, this.label = 'Wapi réfléchit'});

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots> {
  int _dots = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _dots = (_dots % 3) + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        SizedBox(
          width: 18,
          child: Text(
            '.' * _dots,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
