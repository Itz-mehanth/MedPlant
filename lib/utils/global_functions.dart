import 'package:flutter/material.dart';
import 'package:simplytranslate/simplytranslate.dart';

final st = SimplyTranslator(EngineType.google);

// List<PlantBoxWidget> plantWidgets = [];

String currentLocale = "";

Future<String> translate(String text) async {
  if (currentLocale == "en") {
    return text;
  }
  String translatedText = text;
  int retries = 3;

  for (int i = 0; i < retries; i++) {
    try {
      // Randomly switch to a different SimplyTranslate instance
      st.setSimplyInstance = (st.getSimplyInstances..shuffle()).first;

      // Perform the translation
      translatedText = await st.trSimply(text, 'en', currentLocale);

      // If the translation is successful, break the loop
      if (translatedText.isNotEmpty) {
        break;
      }
    } catch (e) {
      print('Error translating text: $e');
      // If the last retry also fails, return the original text
      if (i == retries - 1) {
        translatedText = text;
      }
    }
  }

  return translatedText;
}

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const TranslatedText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: translate(text),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data!, style: style);
        } else {
          return Text(text,
              style: style); // Display the original text while translating
        }
      },
    );
  }
}
