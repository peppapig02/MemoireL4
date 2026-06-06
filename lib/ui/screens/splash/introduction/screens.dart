import 'package:botroad/ui/screens/auth/auth.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroductionScreens extends StatelessWidget {
  IntroductionScreens({super.key});

  final listPagesViewModel = [
    PageViewModel(
      title: "L'assistant intelligent",
      body:
          "Parlez naturellement, BotRoad vous guide. Grace a notre assistant IA, demandez un itineraire, posez une question ou explorez un lieu comme si vous parliez a un ami.",
      image: Container(
        padding: const EdgeInsets.only(top: 50),
        height: 500,
        width: double.infinity,
        child: Image.asset(Assets.intro_sreen_1),
      ),
    ),
    PageViewModel(
      title: "Navigation intelligente",
      body:
          "Un itineraire clair, precis et interactif. BotRoad combine GPS, Google Maps et IA pour tracer des trajets fiables, ajouter des etapes et explorer facilement.",
      image: Container(
        padding: const EdgeInsets.only(top: 50),
        height: 500,
        width: double.infinity,
        child: Image.asset(Assets.intro_sreen_2),
      ),
    ),
    PageViewModel(
      title: "Services complets",
      body:
          "Creez, explorez et profitez sans limite. Connectez-vous, consultez votre historique et decouvrez des lieux tendances.",
      image: Container(
        padding: const EdgeInsets.only(top: 50),
        height: 500,
        width: double.infinity,
        child: Image.asset(Assets.intro_sreen_3),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: listPagesViewModel,
      showBackButton: true,
      showNextButton: false,
      back: const Icon(Icons.arrow_back),
      done: ElevatedButton(
        onPressed: () {
          Get.offAll(() => const AuthScreen());
        },
        child: const Text("Continuer", style: TextStyle(fontSize: 10)),
      ),
      onDone: () {
        Get.offAll(() => const AuthScreen());
      },
    );
  }
}
