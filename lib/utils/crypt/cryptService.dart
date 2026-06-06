import 'package:encrypt_decrypt_plus/encrypt_decrypt/xor.dart';
import 'package:flutter/foundation.dart';

class CryptDecrypt {
  String keycrypt = "botroad#";

  XOR xor = XOR(secretKey: "botroad#");
  // XOR XOR = XOR(secretKey: "linkindappETAcesar1004");
  // XOR XOR = XOR(secretKey: "linkindappETAcesar1004");

  // String encryptTxt = XOR.xorEncode("Hello datadirr");
  // String decryptTxt = XOR.xorDecode(encryptTxt);
  String decrypt(String encrypttext) {
    xor = XOR(secretKey: keycrypt);
    try {
      String decryptTxt = xor.xorDecode(encrypttext);
      return decryptTxt;
    } catch (e) {
      if (kDebugMode) {
        print("error decrypt $encrypttext $e");
      }
      return encrypttext;
    }
  }

  String encrypt(String text) {
    xor = XOR(secretKey: keycrypt);
    try {
      String encryptTxt = xor.xorEncode(text);

      return encryptTxt;
    } catch (e) {
      if (kDebugMode) {
        // print("error encrypt $e");
      }
      return text;
    }
  }

  String decryptWithKey(String encrypttext, [String? key]) {
    try {
      String decryptTxt = xor.xorDecode(encrypttext);
      return decryptTxt;
    } catch (e) {
      if (kDebugMode) {
        print("error decrypt $e");
      }
      return "";
    }
  }

  String encryptWithKey(String text, [String? key]) {
    try {
      String encryptTxt = xor.xorEncode(text);
      return encryptTxt;
    } catch (e) {
      if (kDebugMode) {
        print("error encrypt $e");
      }
      return "";
    }
  }
}
