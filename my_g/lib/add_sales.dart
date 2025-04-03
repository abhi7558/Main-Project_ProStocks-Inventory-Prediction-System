import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:my_g/sales_page.dart'; // Import SalesPage

class AddSalesPage extends StatefulWidget {
  const AddSalesPage({super.key});

  @override
  State<AddSalesPage> createState() => _AddSalesPageState();
}

class _AddSalesPageState extends State<AddSalesPage> {
  String? loginId;
  List<dynamic> products = [];
  String? selectedProductId;
  TextEditingController customerController = TextEditingController();
  TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLoginId();
  }

  Future<void> fetchLoginId() async {
    final SharedPreferences sh = await SharedPreferences.getInstance();
    loginId = sh.getString("lid");
    if (loginId != null) {
      fetchProducts();
    }
  }

  Future<void> fetchProducts() async {
    final SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString("url") ?? "";
    String url = baseUrl + "get_employee_department_products";

    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"login_id": loginId}),
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          products = jsonData['products'];
        });
      } else {
        showError(jsonData['message']);
      }
    } else {
      showError("Failed to load products");
    }
  }

  Future<void> addSale() async {
    if (selectedProductId == null || customerController.text.isEmpty || quantityController.text.isEmpty) {
      showError("Please fill all fields");
      return;
    }

    int quantity = int.tryParse(quantityController.text) ?? 0;
    if (quantity <= 0) {
      showError("Enter a valid quantity");
      return;
    }

    final SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString("url") ?? "";
    String loginId = sh.getString("lid") ?? "";

    var response = await http.post(
      Uri.parse(baseUrl + "add_sale"),
      body: {
        "login_id": loginId,
        "product_id": selectedProductId,
        "customer_name": customerController.text,
        "quantity": quantity.toString(),
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        showSuccess("Sale added successfully");
        customerController.clear();
        quantityController.clear();
        setState(() {
          selectedProductId = null;
        });

        // Navigate to SalesPage and replace current page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SalesPage()),
        );
      } else {
        showError(jsonData['message']);
      }
    } else {
      showError("Failed to add sale");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Sale")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Product:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedProductId,
              hint: const Text("Choose a product"),
              items: products.map<DropdownMenuItem<String>>((product) {
                return DropdownMenuItem<String>(
                  value: product['id'].toString(),
                  child: Text("${product['name']} - \$${product['price']}"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProductId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text("Customer Name:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: customerController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter customer name"),
            ),
            const SizedBox(height: 20),
            const Text("Quantity:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter quantity"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addSale,
              child: const Text("Submit Sale"),
            ),
          ],
        ),
      ),
    );
  }
}