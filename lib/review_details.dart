import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This page shows the detailed information of a specific review.
// It fetches the review document from Firestore based on userId, entryId, and reviewId passed via navigation arguments.

class ReviewDetailPage extends StatelessWidget {
  const ReviewDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the data passed from the previous screen (userId, entryId, reviewId)
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // If any required argument is missing, show an error message
    if (data == null ||
        data['userId'] == null ||
        data['entryId'] == null ||
        data['reviewId'] == null) {
      return const Scaffold(
        body: Center(child: Text('Missing review parameters')),
      );
    }

    // Extract the required IDs from the navigation arguments
    final userId = data['userId'];
    final entryId = data['entryId'];
    final reviewId = data['reviewId'];

    // Reference to the specific review document in Firestore
    final reviewRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(entryId)
        .collection('reviews')
        .doc(reviewId);

    // WillPopScope allows us to control what happens when the user presses the back button
    return WillPopScope(
      onWillPop: () async {
        // When going back, send back the original arguments to previous screen
        Navigator.pop(context, {...data});
        return false; // Prevent the default pop behavior, since we handled it
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Detail'),
          backgroundColor: Colors.blueAccent,
        ),

        // Fetch the review document from Firestore asynchronously
        body: FutureBuilder<DocumentSnapshot>(
          future: reviewRef.get(), // Load the review data once
          builder: (context, snapshot) {
            // Show a loading spinner while data is being fetched
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // If document doesn't exist or there was an issue, show a message
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Review not found'));
            }

            // Extract review data as a Map
            final review = snapshot.data!.data() as Map<String, dynamic>;

            // Display the review details in a scrollable column
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject:', style: titleStyle),
                  Text(review['subject'] ?? 'No subject', style: contentStyle),

                  const SizedBox(height: 20),

                  Text('Description:', style: titleStyle),
                  Text(
                    review['description'] ?? 'No description',
                    style: contentStyle,
                  ),

                  const SizedBox(height: 20),

                  Text('Sent By:', style: titleStyle),
                  Text(review['sentBy'] ?? 'Unknown', style: contentStyle),

                  const SizedBox(height: 20),

                  Text('Timestamp:', style: titleStyle),
                  Text(
                    _formatTimestamp(review['timestamp']),
                    style: contentStyle,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Text style for field titles (e.g., "Subject:")
  TextStyle get titleStyle =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  // Text style for field content (e.g., "Meeting with HR")
  TextStyle get contentStyle => const TextStyle(fontSize: 16);

  // Converts Firestore Timestamp to a human-readable date and time string
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return "${_monthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} – "
          "${_formatTime(dateTime)}";
    }
    return 'Unknown';
  }

  // Formats a DateTime to a readable time string (e.g., 3:45 PM)
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  // Converts month number to a short month name (e.g., 1 → Jan)
  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
