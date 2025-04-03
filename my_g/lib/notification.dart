// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // Added missing import
// import 'package:shared_preferences/shared_preferences.dart';
//
// class NotificationPage extends StatefulWidget {
//   @override
//   _NotificationPageState createState() => _NotificationPageState();
// }
//
// class _NotificationPageState extends State<NotificationPage> {
//   List<dynamic> notifications = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchNotifications();
//   }
//
//   Future<void> fetchNotifications() async {
//     final sh = await SharedPreferences.getInstance();
//     String url = sh.getString("url") ?? "";
//     String lid = sh.getString("lid") ?? "";
//
//     final response = await http.post(
//       Uri.parse(url + "view_sales_notifications"),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode({'login_id': lid}),
//     );
//
//     try {
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 'success') {
//           setState(() {
//             notifications = data['notifications'];
//             isLoading = false;
//           });
//         } else {
//           throw Exception(data['message']);
//         }
//       } else {
//         throw Exception('Failed to load notifications');
//       }
//     } catch (e) {
//       print('Error: $e');
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading notifications: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.teal[700],
//         title: Text('Sales Notifications'),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : notifications.isEmpty
//           ? Center(child: Text('No pending notifications'))
//           : ListView.builder(
//         padding: EdgeInsets.all(16.0),
//         itemCount: notifications.length,
//         itemBuilder: (context, index) {
//           final notification = notifications[index];
//           return Card(
//             elevation: 4,
//             margin: EdgeInsets.symmetric(vertical: 8.0),
//             child: Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Sale ID: ${notification['sale_id']}',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text('Customer: ${notification['customer_name']}'),
//                   Text('Product: ${notification['product_name']}'),
//                   Text('Quantity: ${notification['quantity']}'),
//                   Text('Total: \$${notification['total']}'),
//                   Text('Date: ${notification['date']}'),
//                   Text('Time: ${notification['time']}'),
//                   Text('Employee: ${notification['employee_name']}'),
//                   SizedBox(height: 8),
//                   Text(
//                     'Status: ${notification['status']}',
//                     style: TextStyle(
//                       color: Colors.orange,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  DateTime? selectedDate;
  List<Map<String, dynamic>> salesData = [];
  List<Map<String, dynamic>> orderData = [];
  List<Map<String, dynamic>> filteredSalesData = [];
  List<Map<String, dynamic>> filteredOrderData = [];

  @override
  void initState() {
    super.initState();
    fetchSalesAndOrders();
  }

  Future<void> fetchSalesAndOrders() async {
    final SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString("url") ?? "";
    String loginId = sh.getString("lid") ?? "";

    var response = await http.post(
      Uri.parse(baseUrl+"employee_view_noti"),
      body: {"lid": loginId},
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (jsonData['status'] == 'ok') {
        setState(() {
          salesData = List<Map<String, dynamic>>.from(jsonData['sales_data']);
          orderData = List<Map<String, dynamic>>.from(jsonData['order_data']);
          filteredSalesData = List.from(salesData);
          filteredOrderData = List.from(orderData);
        });
      } else {
        showError("Failed to fetch data");
      }
    } else {
      showError("Server Error");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // Earliest allowed date
      lastDate: DateTime.now(),  // Prevent future dates
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        filterByDate();
      });
    }
  }


  // Filter Sales & Orders by Date
  void filterByDate() {
    if (selectedDate == null) {
      filteredSalesData = List.from(salesData);
      filteredOrderData = List.from(orderData);
      return;
    }

    String selectedDateString = selectedDate!.toString().split(' ')[0];

    setState(() {
      filteredSalesData = salesData
          .where((sale) => sale['Date'] == selectedDateString)
          .toList();

      filteredOrderData = orderData
          .where((order) => order['date'] == selectedDateString)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade700, Colors.green.shade400],
          ),
        ),
        child: Column(
          children: [
            // Date Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                ],
              ),
            ),
            // Tabs for Sales and Orders
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: "Sales"),
                        Tab(text: "Details"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Sales List
                          buildSalesList(),
                          // Orders List
                          buildOrdersList(),
                        ],
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

  Widget buildSalesList() {
    return filteredSalesData.isEmpty
        ? const Center(child: Text("No sales found for selected date"))
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filteredSalesData.length,
      itemBuilder: (context, index) {
        final sale = filteredSalesData[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(
                sale['id'].toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(sale['product_name']),
            subtitle:Column(children: [Text('Date: ${sale['Date']}'),Text('Status: ${sale['status']}')],) ,
            trailing: Text(
              '\$${sale['total'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildOrdersList() {
    return filteredOrderData.isEmpty
        ? const Center(child: Text("No orders found for selected date"))
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filteredOrderData.length,
      itemBuilder: (context, index) {
        final order = filteredOrderData[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                order['id'].toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(order['customer_name']),
            subtitle: Text('Product: ${order['product_name']}'),
            trailing: Text(
              '\$${order['total'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        );
      },
    );
  }
}
