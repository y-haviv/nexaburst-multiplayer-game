// nexaburst/lib/screens/main_components/lunguage_field.dart

import 'package:flutter/material.dart';
import 'package:nexaburst/constants.dart';
import 'package:nexaburst/models/data/service/translation_controllers.dart';

/// A custom form field widget for selecting a language from a predefined list.
///
/// Displays a text field that opens a modal bottom sheet for language selection
/// when tapped. The selected language code is saved using the provided [onSaved] callback.
class LanguageField extends StatefulWidget {
  /// The initially selected language code (e.g., 'en', 'es').
  ///
  /// If provided, the corresponding language name will be displayed in the field.
  final String? initialCode;

  /// Callback invoked when the form is saved, passing the selected language code.
  final FormFieldSetter<String> onSaved;

  /// Creates a [LanguageField] with an optional initial language code and a required [onSaved] callback.
  const LanguageField({super.key, this.initialCode, required this.onSaved});

  @override
  _LanguageFieldState createState() => _LanguageFieldState();
}

/// State class for the [LanguageField] widget, managing UI, filtering, and selection logic.
class _LanguageFieldState extends State<LanguageField> {
  /// Controller for managing the display text in the language selection field.
  final TextEditingController _controller = TextEditingController();

  /// Stores the currently selected language code.
  String? _selectedCode;

  /// Holds the current text used to filter language options in the selection sheet.
  String _filter = '';

  /// A map of supported languages where the key is the display name and the value is the language code.
  final Map<String, String> languages = {
    'afrikaans': 'af',
    'albanian': 'sq',
    'amharic': 'am',
    'arabic': 'ar',
    'armenian': 'hy',
    'assamese': 'as',
    'aymara': 'ay',
    'azerbaijani': 'az',
    'bambara': 'bm',
    'basque': 'eu',
    'belarusian': 'be',
    'bengali': 'bn',
    'bhojpuri': 'bho',
    'bosnian': 'bs',
    'bulgarian': 'bg',
    'catalan': 'ca',
    'cebuano': 'ceb',
    'chichewa': 'ny',
    'chinese (simplified)': 'zh-CN',
    'chinese (traditional)': 'zh-TW',
    'corsican': 'co',
    'croatian': 'hr',
    'czech': 'cs',
    'danish': 'da',
    'dhivehi': 'dv',
    'dogri': 'doi',
    'dutch': 'nl',
    'english': 'en',
    'esperanto': 'eo',
    'estonian': 'et',
    'ewe': 'ee',
    'filipino': 'tl',
    'finnish': 'fi',
    'french': 'fr',
    'frisian': 'fy',
    'galician': 'gl',
    'georgian': 'ka',
    'german': 'de',
    'greek': 'el',
    'guarani': 'gn',
    'gujarati': 'gu',
    'haitian creole': 'ht',
    'hausa': 'ha',
    'hawaiian': 'haw',
    'hebrew': 'iw',
    'hindi': 'hi',
    'hmong': 'hmn',
    'hungarian': 'hu',
    'icelandic': 'is',
    'igbo': 'ig',
    'ilocano': 'ilo',
    'indonesian': 'id',
    'irish': 'ga',
    'italian': 'it',
    'japanese': 'ja',
    'javanese': 'jw',
    'kannada': 'kn',
    'kazakh': 'kk',
    'khmer': 'km',
    'kinyarwanda': 'rw',
    'konkani': 'gom',
    'korean': 'ko',
    'krio': 'kri',
    'kurdish (kurmanji)': 'ku',
    'kurdish (sorani)': 'ckb',
    'kyrgyz': 'ky',
    'lao': 'lo',
    'latin': 'la',
    'latvian': 'lv',
    'lingala': 'ln',
    'lithuanian': 'lt',
    'luganda': 'lg',
    'luxembourgish': 'lb',
    'macedonian': 'mk',
    'maithili': 'mai',
    'malagasy': 'mg',
    'malay': 'ms',
    'malayalam': 'ml',
    'maltese': 'mt',
    'maori': 'mi',
    'marathi': 'mr',
    'meiteilon (manipuri)': 'mni-Mtei',
    'mizo': 'lus',
    'mongolian': 'mn',
    'myanmar': 'my',
    'nepali': 'ne',
    'norwegian': 'no',
    'odia (oriya)': 'or',
    'oromo': 'om',
    'pashto': 'ps',
    'persian': 'fa',
    'polish': 'pl',
    'portuguese': 'pt',
    'punjabi': 'pa',
    'quechua': 'qu',
    'romanian': 'ro',
    'russian': 'ru',
    'samoan': 'sm',
    'sanskrit': 'sa',
    'scots gaelic': 'gd',
    'sepedi': 'nso',
    'serbian': 'sr',
    'sesotho': 'st',
    'shona': 'sn',
    'sindhi': 'sd',
    'sinhala': 'si',
    'slovak': 'sk',
    'slovenian': 'sl',
    'somali': 'so',
    'spanish': 'es',
    'sundanese': 'su',
    'swahili': 'sw',
    'swedish': 'sv',
    'tajik': 'tg',
    'tamil': 'ta',
    'tatar': 'tt',
    'telugu': 'te',
    'thai': 'th',
    'tigrinya': 'ti',
    'tsonga': 'ts',
    'turkish': 'tr',
    'turkmen': 'tk',
    'twi': 'ak',
    'ukrainian': 'uk',
    'urdu': 'ur',
    'uyghur': 'ug',
    'uzbek': 'uz',
    'vietnamese': 'vi',
    'welsh': 'cy',
    'xhosa': 'xh',
    'yiddish': 'yi',
    'yoruba': 'yo',
    'zulu': 'zu',
  };

  /// A sorted list of the language map entries, used for filtering and display.
  late final List<MapEntry<String, String>> _entries;

  /// Initializes the state by populating and sorting language entries.
  ///
  /// If [widget.initialCode] is set, it preselects the corresponding language.
  @override
  void initState() {
    super.initState();
    _entries = languages.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (widget.initialCode != null) {
      final match = _entries.firstWhere(
        (e) => e.value == widget.initialCode,
        orElse: () => MapEntry('', ''),
      );
      if (match.key.isNotEmpty) {
        _controller.text = match.key;
        _selectedCode = match.value;
      }
    }
  }

  /// Builds the main UI for the language selection field.
  ///
  /// Tapping the field opens a bottom sheet for selecting a language.
  @override
  Widget build(BuildContext context) {
    _filter = '';
    return GestureDetector(
      onTap: () => _openSelectionSheet(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: TranslationService.instance.t(
              'screens.settings.select_language_label',
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(AppNumbers.defaultPadding),
              child: const Icon(Icons.language),
            ),
            errorStyle: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          validator: (v) {
            if ((_selectedCode ?? '').isEmpty) {
              return TranslationService.instance.t(
                'screens.settings.select_language_request',
              );
            }
            return null;
          },
          onSaved: (_) {
            widget.onSaved(_selectedCode!);
          },
        ),
      ),
    );
  }

  /// Opens a modal bottom sheet allowing users to search and select a language.
  ///
  /// The selected value updates the form field and stores the language code.
  void _openSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Center(
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final filtered = _entries
                  .where(
                    (e) => e.key.toLowerCase().contains(_filter.toLowerCase()),
                  )
                  .toList();

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: AppNumbers.defaultPadding,
                  right: AppNumbers.defaultPadding,
                  top: 16,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: TranslationService.instance.t(
                                'screens.settings.search_language',
                              ),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (v) {
                              setState(() => _filter = v);
                              setSheetState(() {});
                            },
                          ),
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final entry = filtered[i];
                              return ListTile(
                                title: Text(entry.key),
                                onTap: () {
                                  setState(() {
                                    _controller.text = entry.key;
                                    _selectedCode = entry.value;
                                  });
                                  if(_selectedCode!=null && languages.values.contains(_selectedCode)) widget.onSaved(_selectedCode!);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Disposes the controller and resets the filter when the widget is removed from the tree.
  @override
  void dispose() {
    _filter = '';
    _controller.dispose();
    super.dispose();
  }
}
