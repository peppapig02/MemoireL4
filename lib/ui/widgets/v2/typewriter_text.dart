import 'dart:async';

import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

/// Texte animé type machine à écrire, boucle sur plusieurs phrases.
class TypewriterText extends StatefulWidget {
  final List<String> phrases;
  final TextStyle? style;
  final Duration charDelay;
  final Duration pauseBetweenPhrases;

  const TypewriterText({
    super.key,
    required this.phrases,
    this.style,
    this.charDelay = const Duration(milliseconds: 55),
    this.pauseBetweenPhrases = const Duration(milliseconds: 1800),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _phraseIndex = 0;
  int _charIndex = 0;
  String _displayed = '';
  Timer? _timer;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(widget.charDelay, _tick);
  }

  void _tick() {
    if (!mounted || widget.phrases.isEmpty) return;

    final phrase = widget.phrases[_phraseIndex];

    if (!_deleting) {
      if (_charIndex < phrase.length) {
        setState(() {
          _charIndex++;
          _displayed = phrase.substring(0, _charIndex);
        });
        _scheduleNext();
      } else {
        _timer = Timer(widget.pauseBetweenPhrases, () {
          if (mounted) {
            setState(() => _deleting = true);
            _scheduleNext();
          }
        });
      }
    } else {
      if (_charIndex > 0) {
        setState(() {
          _charIndex--;
          _displayed = phrase.substring(0, _charIndex);
        });
        _scheduleNext();
      } else {
        setState(() {
          _deleting = false;
          _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
        });
        _scheduleNext();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed.isEmpty ? ' ' : _displayed,
      style: widget.style ??
          Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
      textAlign: TextAlign.center,
    );
  }
}
