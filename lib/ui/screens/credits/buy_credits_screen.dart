import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BuyCreditsScreen extends StatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  State<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends State<BuyCreditsScreen> {
  String selectedPaymentMethod = 'mobile_money';
  String selectedCurrency = 'CDF';
  String selectedPackage = 'mini';
  final TextEditingController _phoneController = TextEditingController();

  final Map<String, Map<String, dynamic>> packages = {
    'mini': {'credits': 10, 'price_cdf': 2500, 'price_usd': 0.99},
    'standard': {'credits': 50, 'price_cdf': 10000, 'price_usd': 3.99},
    'premium': {'credits': 100, 'price_cdf': 20000, 'price_usd': 6.99},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acheter des crédits'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du package
            const Text(
              'Choisissez un package',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...packages.entries.map((package) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  title: Text('${package.value['credits']} crédits'),
                  subtitle: Text(
                    selectedCurrency == 'CDF'
                        ? '${package.value['price_cdf']} CDF'
                        : '\$${package.value['price_usd']}',
                  ),
                  value: package.key,
                  groupValue: selectedPackage,
                  onChanged: (value) {
                    setState(() {
                      selectedPackage = value!;
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 24),

            // Sélection de la devise
            const Text(
              'Choisissez la devise',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('CDF'),
                    value: 'CDF',
                    groupValue: selectedCurrency,
                    onChanged: (value) {
                      setState(() {
                        selectedCurrency = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('USD'),
                    value: 'USD',
                    groupValue: selectedCurrency,
                    onChanged: (value) {
                      setState(() {
                        selectedCurrency = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Méthode de paiement
            const Text(
              'Méthode de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Mobile Money'),
                    value: 'mobile_money',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  if (selectedPaymentMethod == 'mobile_money')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          hintText: 'Ex: +243 123456789',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  RadioListTile<String>(
                    title: const Text('Carte Visa'),
                    value: 'visa',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedPaymentMethod == 'mobile_money') {
                    if (_phoneController.text.isEmpty) {
                      Get.snackbar(
                        'Erreur',
                        'Veuillez entrer un numéro de téléphone',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    // TODO: Implémenter le paiement mobile money
                    Get.snackbar(
                      'Succès',
                      'Paiement mobile money initié',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    // Vérifier le montant minimum pour Visa
                    if (selectedCurrency == 'USD' &&
                        packages[selectedPackage]!['price_usd'] < 5) {
                      Get.snackbar(
                        'Erreur',
                        'Le montant minimum pour Visa est de \$5',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    // TODO: Rediriger vers la page de paiement externe
                    Get.snackbar(
                      'Redirection',
                      'Vous allez être redirigé vers la page de paiement',
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Procéder au paiement',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
