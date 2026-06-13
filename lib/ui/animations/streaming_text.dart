import 'dart:async';

import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

/// Révélation progressive du texte bot, ligne par ligne.
class StreamingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool animate;

  const StreamingText({
    super.key,
    required this.text,
    this.style,
    this.animate = true,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  int _visibleLines = 0;
  Timer? _timer;
  late List<String> _lines;

  @override
  void initState() {
    super.initState();
    _lines = widget.text.split('\n');
    if (!widget.animate || widget.text.isEmpty) {
      _visibleLines = _lines.length;
    } else {
      _startReveal();
    }
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _lines = widget.text.split('\n');
      if (!widget.animate) {
        _visibleLines = _lines.length;
      } else {
        _visibleLines = 0;
        _startReveal();
      }
    }
  }

  void _startReveal() {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_visibleLines >= _lines.length) {
        t.cancel();
        return;
      }
      setState(() => _visibleLines++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        TextStyle(color: AppColors.textPrimary, fontSize: 15);

    return AnimatedSize(
      duration: AppAnimations.normal,
      curve: AppAnimations.ease,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_visibleLines.clamp(0, _lines.length), (i) {
          return AnimatedOpacity(
            opacity: 1,
            duration: AppAnimations.fast,
            child: Padding(
              padding: EdgeInsets.only(bottom: i < _lines.length - 1 ? 4 : 0),
              child: Text(_lines[i], style: style),
            ),
          );
        }),
      ),
    );
  }
}
