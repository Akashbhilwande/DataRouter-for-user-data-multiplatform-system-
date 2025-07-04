// Core Flutter & Firebase imports
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:hive_flutter/adapters.dart';
import 'package:hive/hive.dart';

// Local imports
import 'Messaging/fcm_service.dart';
import 'firebase_options.dart';
import 'review_details.dart';
import 'login_page.dart';
import 'my_submissions.dart';
import 'review_screen.dart';
import 'user_info.dart';
import 'edit_profile.dart';

// Background message handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

// Global navigation key used for navigation outside of widget context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handlers
  FirebaseMessaging.onBackgroundMessage(
    FCMService.firebaseMessagingBackgroundHandler,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Hive and open local storage box
  await Hive.initFlutter();
  Hive.registerAdapter(UserInfoModelAdapter());
  await Hive.openBox<UserInfoModel>('user_info_box');

  // Initialize FCM and handle any initial messages
  await FCMService.initFCM(navigatorKey);
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  // Start the app
  runApp(MyApp(initialMessage: initialMessage));
}

class MyApp extends StatelessWidget {
  final RemoteMessage? initialMessage;
  const MyApp({super.key, this.initialMessage});

  @override
  Widget build(BuildContext context) {
    // Handle initial notification if app was opened via FCM
    if (initialMessage != null) {
      final data = initialMessage!.data;
      final userId = data['userId'];
      final entryId = data['entryId'];
      final reviewId = data['reviewId'];

      if (userId != null && entryId != null && reviewId != null) {
        Future.delayed(Duration.zero, () {
          navigatorKey.currentState?.pushNamed(
            '/review',
            arguments: {
              'userId': userId,
              'entryId': entryId,
              'reviewId': reviewId,
            },
          );
        });
      }
    }

    // MaterialApp setup with route definitions
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'User Info Saver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade200,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => LoginPage(),
        '/submissions': (context) => const MySubmissionsPage(),
        '/userform': (context) => const UserForm(),
        '/review': (context) => ReviewPage(),
        '/reviewDetail': (context) => const ReviewDetailPage(),
        '/editprofile': (context) => EditProfilePage(),
      },
    );
  }
}

// Handles navigation based on user authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? LoginPage() : const UserForm();
  }
}

// Main user form widget
class UserForm extends StatefulWidget {
  const UserForm({super.key});

  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  Position? _currentPosition;
  String? _selectedRegion;

  // Predefined list of regions
  final List<String> _regions = [
    'Mumbai',
    'Delhi',
    'Noida',
    'Hyderabad',
    'Chennai',
    'Pune',
    'Kolkata',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _syncOfflineData();

    // Listen for connectivity changes to retry sync
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncOfflineData();
      }
    });

    // Handle notification if tapped when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        final data = message.data;
        final userId = data['userId'];
        final entryId = data['entryId'];
        final reviewId = data['reviewId'];

        if (userId != null && entryId != null && reviewId != null) {
          navigatorKey.currentState?.pushNamed(
            '/reviewDetail',
            arguments: {
              'userId': userId,
              'entryId': entryId,
              'reviewId': reviewId,
            },
          );
        }
      }
    });
  }

  // Get current location using geolocator
  void _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.requestPermission();

    if (serviceEnabled &&
        permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    }
  }

  // Check for internet connection
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Submit form data to Firebase or save locally if offline
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRegion == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a region')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    final userData = UserInfoModel(
      userId: user.uid,
      name: nameController.text.trim(),
      company: companyController.text.trim(),
      contact: contactController.text.trim(),
      timestamp: DateTime.now(),
      latitude: _currentPosition?.latitude ?? 0.0,
      longitude: _currentPosition?.longitude ?? 0.0,
      submitterEmail: user.email ?? 'Unknown',
      submitterDisplayName: user.displayName,
      region: _selectedRegion!,
    );

    final isOnline = await hasInternet();
    final box = Hive.box<UserInfoModel>('user_info_box');

    if (isOnline) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('entries')
            .add(userData.toMap());

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data saved to Firebase')));
      } catch (e) {
        // Save locally if Firebase fails
        await box.add(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally due to Firebase error')),
        );
      }
    } else {
      // Save locally when offline
      await box.add(userData);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offline. Saved locally')));
    }

    _clearFormFields();
  }

  // Clear form input fields after submission
  void _clearFormFields() {
    nameController.clear();
    companyController.clear();
    contactController.clear();
    setState(() {
      _selectedRegion = null;
    });
  }

  // Sync offline data stored in Hive to Firebase
  void _syncOfflineData() async {
    final box = Hive.box<UserInfoModel>('user_info_box');
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && box.isNotEmpty) {
      bool anySynced = false;

      for (int i = 0; i < box.length;) {
        final entry = box.getAt(i);
        if (entry != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('entries')
                .add(entry.toMap());

            await box.deleteAt(i); // Remove only after successful sync
            anySynced = true;
          } catch (e) {
            print('Sync failed for index $i: $e');
            i++; // Skip increment if delete successful
          }
        } else {
          i++;
        }
      }

      if (anySynced && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline data synced to Firebase')),
        );
        print("You are online, data successfully synced to Firebase.");
      }
    }
  }

  // Main UI build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'GET USER INFO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4,
      ),

      // Side navigation drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'User Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('My Submissions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/submissions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushNamed(
                  context,
                  '/editprofile',
                ); // Navigate to edit profile page
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),

      // Form body
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(35),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Enter Data',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter your name'
                              : null,
                ),
                const SizedBox(height: 20),

                // Company field
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter company name'
                              : null,
                ),
                const SizedBox(height: 20),

                // Contact field
                TextFormField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter contact number'
                              : null,
                ),
                const SizedBox(height: 20),

                // Region dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Select Region',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  items:
                      _regions.map((region) {
                        return DropdownMenuItem<String>(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a region' : null,
                ),
                const SizedBox(height: 25),

                // Submit button
                ElevatedButton.icon(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.check,
                    color: Colors.blueAccent,
                    size: 30,
                  ),
                  label: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 25),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
