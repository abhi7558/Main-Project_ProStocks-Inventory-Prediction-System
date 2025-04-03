import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Request notification permission for Android 14+
  await _requestNotificationPermission(flutterLocalNotificationsPlugin);

  // Initialize settings for Android notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

// Request notification permission (Android 14+)
Future<void> _requestNotificationPermission(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  // final bool? permissionGranted =await flutterLocalNotificationsPlugin.requestPermission();
  //
  // if (permissionGranted != null && permissionGranted) {
  //   print("Notification permission granted");
  // } else {
  //   print("Notification permission denied");
  // }
}

// Show a test notification
Future<void> showNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  var androidDetails = AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.high,
    priority: Priority.high,
  );

  var platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Notification',
    'This is a test notification!',
    platformDetails,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notification Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();
            await showNotification(flutterLocalNotificationsPlugin);
          },
          child: Text('Show Notification'),
        ),
      ),
    );
  }
}
