import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'data/list_repository.dart';
import 'l10n/app_localizations.dart';
import 'settings/settings.dart';
import 'ui/lists_screen.dart';

/// Used when the OS doesn't provide a Material You palette.
const _fallbackSeedColor = Color(0xFF2E7D32);

class ShopperApp extends StatelessWidget {
  const ShopperApp({super.key, required this.lists, required this.settings});

  final ListRepository lists;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: ThemeData(
            colorScheme:
                lightDynamic ??
                ColorScheme.fromSeed(seedColor: _fallbackSeedColor),
          ),
          darkTheme: ThemeData(
            colorScheme:
                darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: _fallbackSeedColor,
                  brightness: Brightness.dark,
                ),
          ),
          themeMode: ThemeMode.system,
          // Material/Cupertino/Widgets translations come from material_ui,
          // not from the legacy flutter_localizations package.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListsScreen(lists: lists, settings: settings),
        );
      },
    );
  }
}
