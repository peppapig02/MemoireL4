import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

/// Section accordéon fluide pour le profil.
class AccordionSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const AccordionSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<AccordionSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: AppAnimations.normal,
                  curve: AppAnimations.ease,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: widget.child,
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppAnimations.normal,
          sizeCurve: AppAnimations.ease,
        ),
      ],
    );
  }
}
