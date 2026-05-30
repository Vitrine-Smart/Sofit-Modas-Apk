// ============================================================
//  SOFIT MODAS — main.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'controllers/cart_controller.dart';
import 'screens/catalog_screen.dart';

void main() async {
  // Garante que os bindings nativos estejam prontos antes de ligar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase padrão do seu projeto (configurado via google-services.json)
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: const SofitModasApp(),
    ),
  );
}

class SofitModasApp extends StatelessWidget {
  const SofitModasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sofit Modas PDV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial-design: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const CatalogScreen(),
    );
  }
}
