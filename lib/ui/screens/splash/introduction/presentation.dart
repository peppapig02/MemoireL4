import 'package:botroad/ui/screens/credits/buy_credits_screen.dart';
import 'package:botroad/ui/screens/home/home.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Presentation extends StatelessWidget {
  const Presentation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 250, width: 250, child: Image.asset(Assets.logo)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Procurez vous des crédits',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Botroad utilise des crédits pour génerer des prompts IA',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => const BuyCreditsScreen());
                },
                child: Text("Se procurer des crédits"),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.offAll(() => HomeScreen());
              },
              child: Text(
                'Se réaprovisionner plutard',
                style: TextStyle(
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
