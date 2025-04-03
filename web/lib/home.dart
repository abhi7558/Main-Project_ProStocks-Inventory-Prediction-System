import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_g/profile.dart';
import 'package:my_g/sales_page.dart';
import 'package:my_g/change_password_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_g/notification.dart'; // Ensure this matches your file location
import 'package:my_g/review.dart';

class EmployeeHome extends StatelessWidget {
  EmployeeHome() {
    _startPeriodicTask();
    notiload(); // Call notiload during initialization
  }

  Timer? _timer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> notiload() async {
    WidgetsFlutterBinding.ensureInitialized();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestNotificationPermission(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    // Uncomment and implement if needed
  }

  Future<void> showNotification(String s) async {
    var androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    var platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Notification',
      'Your Request status is ' + s,
      platformDetails,
    );
  }

  void _startPeriodicTask() {
    const duration = Duration(seconds: 5);
    _timer = Timer.periodic(duration, (timer) async {
      print('Executing task at ${DateTime.now()}');
      final sh = await SharedPreferences.getInstance();

      String url = sh.getString("url") ?? "";
      String lid = sh.getString("lid") ?? "";

      var data = await http.post(
        Uri.parse(url + "updatelocation"),
        body: {"lid": lid},
      );

      var jasondata = json.decode(data.body);
      String status = jasondata['task'].toString();
      print(status + "+++++++++++++++====++----");
      if (status == "True") {
        String s = jasondata['s'].toString();
        await showNotification(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        elevation: 2,
        title: Text(
          "Logo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.lock, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordPage(employeeId: '2'),
                ),
              );
            },
            tooltip: 'Change Password',
          ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageProfile()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[100]!, Colors.purple[50]!],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureButton(
                  context: context,
                  icon: Icons.trending_up,
                  label: "SALES",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SalesPage()),
                    );
                  },
                ),

                _buildFeatureButton(
                  context: context,
                  icon: Icons.group,
                  label: "REVIEWS",
                  onPressed: () {
                    Navigator.pushNamed(context, '/reviewpage');
                  },
                ),
              ],
            ),
            SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[900],
                        shadows: [
                          Shadow(
                            color: Colors.purple[200]!,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Explore your sales metrics and customer reviews to grow your business.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.purple[800],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal[300]!.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.star,
                          size: 80,
                          color: Colors.purple[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal[100],
            boxShadow: [ // Fixed from boxBodyShadow to boxShadow
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(20),
          child: Icon(
            icon,
            size: 60,
            color: Colors.teal[800],
          ),
        ),
        SizedBox(height: 15),
        GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent[700]!, Colors.purple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}