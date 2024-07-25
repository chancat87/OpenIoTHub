import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openiothub/l10n/generated/openiothub_localizations.dart';
import 'package:openiothub/init.dart';
import 'package:openiothub/model/custom_theme.dart';
import 'package:openiothub/pages/homePage/homePage.dart';
import 'package:openiothub/pages/splashPage/splashPage.dart';
import 'package:provider/provider.dart';
import 'package:oktoast/oktoast.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CustomTheme()),
      ],
      child: const MyApp(),
    ),
    // MyApp()
  );
  init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
        child: MaterialApp(
            title: "云亿连",
            // title: "OpenIoTHub",
            theme: CustomThemes.light,
            darkTheme: CustomThemes.dark,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              OpenIoTHubLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate
            ],
            supportedLocales: OpenIoTHubLocalizations.supportedLocales,
            localeListResolutionCallback: (locales, supportedLocales) {
              print("locales:$locales");
              return;
            },
            home: (Platform.isAndroid || Platform.isIOS)
                ? const SplashPage()
                : MyHomePage(
                    key: UniqueKey(),
                    title: '',
                  )));
  }
}
