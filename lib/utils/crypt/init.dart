import 'package:encrypt/encrypt.dart';

Encrypter get encryptObject => Encrypter(AES(Key.fromLength(32)));