// #################################################
// #            CODE STILL IN PENDING              #
// #################################################

import 'dart:math';

// Covert a string to a random capital and small cases
String getRandomCase(String text) => Random().nextBool() ? text.toUpperCase() : text.toLowerCase();

/// Generates a random alphabetic character with random letter cases with length of 6(default)
String captchaTextWithRandomCase({int? length}) {
  Random random = Random();
  List<int> codeUnits = List<int>.generate(length ?? 6, (int index) => random.nextInt(26) + 65);
  return String.fromCharCodes(codeUnits).splitMapJoin(
    RegExp(r'[A-Z]'),
    onMatch: (Match m) => getRandomCase(m[0]!),
    onNonMatch: (String s) => s,
  );
}

// Generate random color hex code
String randomColorHexCode() {
  Random random = Random();
  return '#${random.nextInt(0xffffff).toRadixString(16).padLeft(6, '0')}';
}
