import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeGetIt();
  runApp(const MrRexApp());
}
