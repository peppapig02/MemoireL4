import 'package:botroad/ui/screens/auth/auth.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroductionScreens extends StatelessWidget {
  IntroductionScreens({super.key});

  var listPagesViewModel = [
    PageViewModel(
      title: "L'assistant intelligent",
      body:
          "Parlez naturellement, Botroad vous guide. Grâce à notre assistant IA, demandez un itinéraire, posez une question ou explorez un lieu — comme si vous parliez à un ami.",
      image: Container(
        padding: EdgeInsets.only(top: 50),
        height: 500,
        width: double.infinity,
        child: Image.asset(Assets.intro_sreen_1),
      ),
    ),
    PageViewModel(
      title: "Navigation intelligente",
      body:
          "Un itinéraire clair, précis, interactif. Botroad combine GPS, Google Maps et IA pour tracer des trajets fiables, ajouter des étapes et explorer facilement.",
      image: Container(
        padding: EdgeInsets.only(top: 50),
        height: 500,
        width: double.infinity,
        child: Image.asset(Assets.intro_sreen_2),
      ),
    ),
    PageViewModel(
      title: "Services complets",
      body:
          "Créez, explorez, profitez sans limite. Connectez-vous, achetez des crédits via Mobile Money ou Visa, consultez votre historique et découvrez des lieux tendances.",
      image: Container(
        padding: EdgeInsets.only(top: 50),
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
        child: Text("Continuer", style: TextStyle(fontSize: 10)),
      ),
      onDone: () {
        Get.offAll(() => const AuthScreen());
      },
    );
  }
}
