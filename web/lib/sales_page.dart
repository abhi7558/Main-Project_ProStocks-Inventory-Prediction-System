import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:url_launcher/url_launcher.dart';
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
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
      Uri.parse(baseUrl + "employee_view_sales"),
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        filterByDate();
      });
    }
  }

  void filterByDate() {
    if (selectedDate == null) {
      filteredSalesData = List.from(salesData);
      filteredOrderData = List.from(orderData);
      return;
    }

    String selectedDateString = selectedDate!.toString().split(' ')[0];

    setState(() {
      filteredSalesData =
          salesData.where((sale) => sale['Date'] == selectedDateString).toList();

      filteredOrderData =
          orderData.where((order) => order['date'] == selectedDateString).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Order History'),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate == null
                        ? 'Select Date to Filter'
                        : 'Date: ${selectedDate!.toString().split(' ')[0]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: "Sales"),
                        Tab(text: "Orders"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          buildSalesList(),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add_sales');
            },
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              final SharedPreferences sh = await SharedPreferences.getInstance();
              String baseUrl = sh.getString("url") ?? "";
              String lid = sh.getString("lid") ?? "";
              print(baseUrl+"employee_sales_report/"+lid);
              final Uri url = Uri.parse(baseUrl+"employee_sales_report/"+lid);
              await launchUrl(baseUrl+"employee_sales_report/"+lid);
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.star),
          ),
        ],
      ),
    );
  }




  Widget buildSalesList() {
    return filteredSalesData.isEmpty
        ? const Center(
      child: Text(
        "No sales found for selected date",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    )
        : ListView.builder(
      itemCount: filteredSalesData.length,
      itemBuilder: (context, index) {
        final sale = filteredSalesData[index];
        return Card(
          color: Colors.white.withOpacity(0.9), // Slightly transparent white
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              sale['product_name'],
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Date: ${sale['Date']}',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        );
      },
    );
  }

  Widget buildOrdersList() {
    return filteredOrderData.isEmpty
        ? const Center(
      child: Text(
        "No orders found for selected date",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    )
        : ListView.builder(
      itemCount: filteredOrderData.length,
      itemBuilder: (context, index) {
        final order = filteredOrderData[index];
        return Card(
          color: Colors.white.withOpacity(0.9), // Slightly transparent white
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              order['customer_name'],
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Product: ${order['product_name']}',
              style: const TextStyle(color: Colors.black87),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Trigger review request action
                _showReviewRequestDialog(context, order['customer_name'], order['id'].toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Review Request'),
            ),
          ),
        );
      },
    );
  }

  void _showReviewRequestDialog(BuildContext context, String customerName, String pid) {
    final TextEditingController phoneNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Review Request for $customerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextFormField(
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {


                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Add your review request logic here
                String phoneNumber = phoneNumberController.text;
                if (phoneNumber.isNotEmpty) {
                  // Trigger the review request with the phone number
                  final SharedPreferences sh = await SharedPreferences.getInstance();
                  String baseUrl = sh.getString("url") ?? "";
                  String loginId = sh.getString("lid") ?? "";

                  var response = await http.post(
                    Uri.parse(baseUrl + "sendsms"),
                    body: {"url": baseUrl+"smsrating?pid="+pid,"name":customerName,"phno":phoneNumberController.text.toString()},
                  );
                  print(response);
                  _sendReviewRequest(customerName, phoneNumber);
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Request Review'),
            ),
          ],
        );
      },
    );
  }

  void _sendReviewRequest(String customerName, String phoneNumber) {
    // Implement your logic to send the review request
    print('Review requested for $customerName with phone number: $phoneNumber');
    // Example: Make an API call to send the review request
  }
}