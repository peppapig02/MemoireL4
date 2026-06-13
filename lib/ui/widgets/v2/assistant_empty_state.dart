import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/scale_tap.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/widgets/v2/typewriter_text.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';

class AssistantEmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;
  final bool visible;

  const AssistantEmptyState({
    super.key,
    required this.onSuggestionTap,
    this.visible = true,
  });

  static const _phrases = [
    'Bienvenue sur BotRoad',
    'Où allons-nous aujourd\'hui ?',
    'Comment puis-je vous aider ?',
    'Trouvons le meilleur itinéraire',
    'Évitons les embouteillages',
  ];

  static const _suggestions = [
    'Trouver un itinéraire',
    'Éviter les embouteillages',
    'Trouver une station-service',
    'Évaluer une route',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppAnimations.slow,
      curve: AppAnimations.exit,
      child: IgnorePointer(
        ignoring: !visible,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: AppAnimations.slow,
                child: Image.asset(
                  Assets.logo_white,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              if (visible)
                TypewriterText(
                  phrases: _phrases,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _suggestions.map((s) {
                  return ScaleTap(
                    pressedScale: AppAnimations.suggestionTapScale,
                    onTap: () => onSuggestionTap(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        s,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
