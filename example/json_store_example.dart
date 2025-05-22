import 'package:flutter/material.dart';
import 'package:json_store/json_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for path_provider
  final jsonstore = await JsonStore.instance();

  // Now you can use jsonstore to interact with your data
  await jsonstore.collection('users').doc('user1').set({
    'name': 'Najee Agha',
    'email': 'noormoh3.com',
  });

  final doc = await jsonstore.collection('users').doc('user1').get();
  print(doc.data); // Output: {name: Najee Agha, email: noormoh3.com}

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Json Store Example')),
        body: Center(child: Text('Check console for Jsonstore output')),
      ),
    );
  }
}
