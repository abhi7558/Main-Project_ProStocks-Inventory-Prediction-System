import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ManageProfile extends StatefulWidget {
  const ManageProfile({super.key});

  @override
  State<ManageProfile> createState() => _ManageProfileState();
}

class _ManageProfileState extends State<ManageProfile> {
  bool _isEditing = false;
  File? _image;
  final _formKey = GlobalKey<FormState>();
  String? _lid;
  String? _baseUrl;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _gender;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadLoginIdAndProfile();
  }

  Future<void> _loadLoginIdAndProfile() async {
    final sh = await SharedPreferences.getInstance();
    _lid = sh.getString("lid");
    if (_lid != null) {
      await _loadProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      Navigator.pop(context); // Return to login screen if no lid
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final sh = await SharedPreferences.getInstance();
      String url = sh.getString("url") ?? "";
      setState(() {
        _baseUrl = url; // Store the base URL
      });

      final response = await http.post(
        Uri.parse(url+"employee_view_profile"),
        body: {'lid': _lid!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            _profileData = data['profile'][0];
            _nameController.text = _profileData!['name'];
            _phoneController.text = _profileData!['Phone'];
            _placeController.text = _profileData!['place'];
            _pinController.text = _profileData!['pin'];
            _postController.text = _profileData!['post'];
            _emailController.text = _profileData!['email'];
            _gender = _profileData!['gender']; // Ensure this matches dropdown values
          });
        } else {
          _showError('Failed to load profile');
        }
      }
    } catch (e) {
      _showError('Error loading profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final sh = await SharedPreferences.getInstance();
      String url = sh.getString("url") ?? "";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(url+"employee_edit_profile"),
      );

      // Add text fields
      request.fields['lid'] = _lid!;
      request.fields['name'] = _nameController.text;
      request.fields['Phone'] = _phoneController.text;
      request.fields['place'] = _placeController.text;
      request.fields['pin'] = _pinController.text;
      request.fields['post'] = _postController.text;
      request.fields['email'] = _emailController.text;
      request.fields['gender'] = _gender ?? '';

      // Add photo if changed
      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _image!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['status'] == 'ok') {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        await _loadProfileData(); // Refresh profile data
      } else {
        _showError('Failed to update profile');
      }
    } catch (e) {
      _showError('Error saving profile: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = !_isEditing);
              }
            },
          ),
        ],
      ),
      body: _lid == null
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: FutureBuilder<String?>(
                  future: SharedPreferences.getInstance().then((sh) => sh.getString("url")),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const CircleAvatar(
                        radius: 60,
                        child: CircularProgressIndicator(), // Show loading while fetching URL
                      );
                    }
                    String baseUrl = snapshot.data!;
                    return CircleAvatar(
                      radius: 60,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : NetworkImage("$baseUrl${_profileData!['photo']}") as ImageProvider,
                      child: _isEditing ? const Icon(Icons.camera_alt, size: 30) : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Employee Code (Read-only)
              Card(
                child: ListTile(
                  title: const Text('Employee Code'),
                  subtitle: Text(_profileData!['employee_code']),
                ),
              ),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                enabled: _isEditing,
                validator: (value) =>
                value!.isEmpty ? 'Name is required' : null,
              ),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value!.isEmpty ? 'Phone is required' : null,
              ),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty ? 'Email is required' : null,
              ),

              // Gender Dropdown - Fixed version
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: _isEditing
                    ? (value) => setState(() => _gender = value)
                    : null,
                validator: (value) =>
                value == null ? 'Please select a gender' : null,
              ),

              // Place Field
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: 'Place'),
                enabled: _isEditing,
              ),

              // Pin Field
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(labelText: 'Pin'),
                enabled: _isEditing,
                keyboardType: TextInputType.number,
              ),

              // Post Field
              TextFormField(
                controller: _postController,
                decoration: const InputDecoration(labelText: 'Post'),
                enabled: _isEditing,
              ),

              // Department (Read-only)
              Card(
                child: ListTile(
                  title: const Text('Department'),
                  subtitle: Text(_profileData!['department_id']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _placeController.dispose();
    _pinController.dispose();
    _postController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}