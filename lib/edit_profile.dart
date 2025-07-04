import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyController = TextEditingController();
  final _designationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load current user's data from Firestore
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _surnameController.text = data['surname'] ?? '';
        _mobileController.text = data['mobile'] ?? '';
        _companyController.text = data['company'] ?? '';
        _designationController.text = data['designation'] ?? '';
      }
    }
    setState(() => _isLoading = false);
  }

  // Save updated data
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final updatedData = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'company': _companyController.text.trim(),
        'designation': _designationController.text.trim(),
        'lastUpdated': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedData);

      // Optionally update the display name in Firebase Auth too
      await user.updateDisplayName(_nameController.text.trim());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _mobileController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile',style: TextStyle(color: Colors.white,fontSize: 26),), backgroundColor:Colors.blue ,),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Name is required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _surnameController,
                        decoration: InputDecoration(labelText: 'Surname'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Surname is required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        decoration: InputDecoration(labelText: 'Mobile Number'),
                        keyboardType: TextInputType.phone,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Mobile number is required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(labelText: 'Company'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Company is required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _designationController,
                        decoration: InputDecoration(labelText: 'Designation'),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Designation is required'
                                    : null,
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        child:
                            _isLoading
                                ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                )
                                : Text('Save Changes',style: TextStyle(color: Colors.blueAccent),),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
