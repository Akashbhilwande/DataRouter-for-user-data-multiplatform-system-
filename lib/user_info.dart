// Import Hive package (used for local/offline storage in Flutter apps)
import 'package:hive/hive.dart';

// This line is needed to generate code that Hive uses to store and retrieve data.
// IMPORTANT: The file name here ('user_info.g.dart') must exactly match the filename of this Dart file.
part 'user_info.g.dart';

// Mark this class as a Hive type with a unique ID (must be a number between 0–223).
@HiveType(typeId: 0)
// This is your custom data model class which Hive will save locally.
// It holds the user's form data like name, contact, location, etc.
class UserInfoModel extends HiveObject {
  // Each @HiveField(n) must have a unique index number.
  // The order matters when Hive reads/writes data. Don't change once deployed!

  @HiveField(0)
  final String userId; // Unique ID for this submission

  @HiveField(1)
  final String name; // Full name entered by user

  @HiveField(2)
  final String company; // Type of company entered by user

  @HiveField(3)
  final String contact; // Contact number

  @HiveField(4)
  final DateTime timestamp; // When the data was saved (used for sorting, syncing)

  @HiveField(5)
  final double latitude; // GPS location (latitude)

  @HiveField(6)
  final double longitude; // GPS location (longitude)

  @HiveField(7)
  final String submitterEmail; // Logged-in user's email (from Firebase Auth)

  @HiveField(8)
  final String? submitterDisplayName; // Optional display name (can be null)

  @HiveField(9)
  final String region; // Region selected in the form

  // Constructor to create a new UserInfoModel object
  UserInfoModel({
    required this.userId,
    required this.name,
    required this.company,
    required this.contact,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.submitterEmail,
    this.submitterDisplayName,
    required this.region,
  });

  // Converts this object into a Map<String, dynamic>
  // Useful for saving to Firebase or debugging
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'company': company,
    'contact': contact,
    'timestamp': timestamp.toIso8601String(), // convert DateTime to string
    'latitude': latitude,
    'longitude': longitude,
    'submitterEmail': submitterEmail,
    'submitterDisplayName': submitterDisplayName,
    'region': region,
  };

  // Creates a UserInfoModel from a Map<String, dynamic>
  // Useful when loading data from Firebase or local JSON
  factory UserInfoModel.fromMap(Map<String, dynamic> map) => UserInfoModel(
    userId: map['userId'],
    name: map['name'],
    company: map['company'],
    contact: map['contact'],
    timestamp: DateTime.parse(map['timestamp']), // convert string to DateTime
    latitude: map['latitude'],
    longitude: map['longitude'],
    submitterEmail: map['submitterEmail'],
    submitterDisplayName: map['submitterDisplayName'],
    region: map['region'],
  );
}
