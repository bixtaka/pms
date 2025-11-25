import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Firebase 初期化をまとめるユーティリティ
Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    await Firebase.initializeApp();
  }

  // 必要に応じて Firestore 設定を追加
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}
