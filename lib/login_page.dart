// Import necessary Flutter and Firebase packages
import 'package:firebase_messaging/firebase_messaging.dart'; // For push notifications
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore database
import 'package:geolocator/geolocator.dart'; // For getting the device's GPS location

// Define a stateful widget for login/registration page
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

// The state of LoginPage holds UI and logic
class _LoginPageState extends State<LoginPage> {
  // Key used to validate the form
  final _formKey = GlobalKey<FormState>();

  // Text controllers to get input from text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyController = TextEditingController();
  final _designationController = TextEditingController();

  // Whether the user is in registration mode
  bool _isRegistering = false;

  // Whether the login/register process is loading
  bool _isLoading = false;

  // Holds the current location of the user (latitude and longitude)
  Position? _currentPosition;

  // Called when the widget is inserted into the tree
  @override
  void initState() {
    super.initState();
    _getLocation(); // Get user’s location when screen loads
  }

  // Function to get the current location using GPS
  Future<void> _getLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // Request permission to access location
    LocationPermission permission = await Geolocator.requestPermission();

    // If permission granted and services are enabled, get the location
    if (serviceEnabled &&
        permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Save the current position in the state
      setState(() {
        _currentPosition = position;
      });
    }
  }

  // Function to handle login
  Future<void> _login() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      // Try to sign in using email and password
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;

      // If user exists, update FCM token in Firestore
      if (user != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'fcmToken': fcmToken, 'lastLogin': DateTime.now()});
        }
      }

      // Navigate to the next screen after successful login
      Navigator.pushReplacementNamed(context, '/userform');
    } on FirebaseAuthException catch (e) {
      // Show error message if login fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
    } finally {
      // Hide loading indicator
      setState(() => _isLoading = false);
    }
  }

  // Function to handle registration
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create a new user with email and password
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;

      if (user != null) {
        // Set user's display name in Firebase Auth
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload(); // Refresh user info

        // Get FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();

        // Prepare user data to save in Firestore
        final userData = {
          'userId': user.uid,
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'company': _companyController.text.trim(),
          'designation': _designationController.text.trim(),
          'latitude': _currentPosition?.latitude ?? 0.0,
          'longitude': _currentPosition?.longitude ?? 0.0,
          'timestamp': DateTime.now(),
          if (fcmToken != null) 'fcmToken': fcmToken,
        };

        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        // Navigate to user form page
        Navigator.pushReplacementNamed(context, '/userform');
      }
    } on FirebaseAuthException catch (e) {
      // Show registration error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.message}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper method to validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  // Helper method to validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // Generic validator for name, surname, company, etc.
  String? _validateText(String? value, String label) {
    if (value == null || value.isEmpty) return '$label is required';
    return null;
  }

  // Build the actual UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isRegistering ? 'Register' : 'Login',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: _validatePassword,
                        ),

                        if (_isRegistering) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateText(v, 'Name'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _surnameController,
                            decoration: const InputDecoration(
                              labelText: 'Surname',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateText(v, 'Surname'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _mobileController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => _validateText(v, 'Mobile Number'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateText(v, 'Company'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _designationController,
                            decoration: const InputDecoration(
                              labelText: 'Designation',
                              prefixIcon: Icon(Icons.work_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _validateText(v, 'Designation'),
                          ),
                        ],

                        const SizedBox(height: 30),

                        ElevatedButton.icon(
                          onPressed:
                              _isLoading
                                  ? null
                                  : (_isRegistering ? _register : _login),
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blueAccent,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.login,
                                    color: Colors.blueAccent,
                                  ),
                          label: Text(
                            _isRegistering ? 'Register' : 'Login',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),

                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => setState(
                                    () => _isRegistering = !_isRegistering,
                                  ),
                          child: Text(
                            _isRegistering
                                ? 'Already have an account? Login'
                                : 'Don\'t have an account? Register',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
