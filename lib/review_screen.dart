import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// This page displays a submission's details along with a list of its associated reviews.
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get arguments passed from previous screen (userId and entryId)
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // If required data is missing, show an error
    if (data == null ||
        !data.containsKey('userId') ||
        !data.containsKey('entryId')) {
      return const Scaffold(body: Center(child: Text('No data provided')));
    }

    // Extract user ID and entry ID
    final String userId = data['userId'];
    final String entryId = data['entryId'];

    // Firestore reference to the specific entry document
    final entryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(entryId);

    // Reference to the reviews subcollection of that entry
    final reviewsRef = entryRef.collection('reviews');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Submission'),
        backgroundColor: Colors.blueAccent,
      ),

      // Fetch the main submission document first
      body: FutureBuilder<DocumentSnapshot>(
        future: entryRef.get(),
        builder: (context, entrySnapshot) {
          if (entrySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!entrySnapshot.hasData || !entrySnapshot.data!.exists) {
            return const Center(child: Text('Submission not found'));
          }

          // Extract all the fields from the submission document
          final submissionFields =
              entrySnapshot.data!.data() as Map<String, dynamic>;

          // Friendly labels for some fields
          final fieldLabels = {
            'name': 'Full Name',
            'company': 'Company Type',
            'contact': 'Contact Number',
            'region': 'Region',
            'timestamp': 'Submitted At',
          };

          // Fields we want to skip showing
          final excludedFields = [
            'latitude',
            'longitude',
            'submitterEmail',
            'submitterDisplayName',
          ];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submission Details:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Display each field in a formatted way, skipping excluded fields
                ...submissionFields.entries
                    .where(
                      (entry) =>
                          fieldLabels.containsKey(entry.key) &&
                          !excludedFields.contains(entry.key),
                    )
                    .map((entry) {
                      final label =
                          fieldLabels[entry.key]!; // Get readable label
                      String valueStr;

                      // Special formatting for timestamps
                      if (entry.key == 'timestamp') {
                        if (entry.value is Timestamp) {
                          final dateTime =
                              (entry.value as Timestamp).toDate().toLocal();
                          valueStr = _formatReadableTimestamp(dateTime);
                        } else if (entry.value is String) {
                          try {
                            final dateTime =
                                DateTime.parse(entry.value).toLocal();
                            valueStr = _formatReadableTimestamp(dateTime);
                          } catch (_) {
                            valueStr = entry.value.toString();
                          }
                        } else {
                          valueStr = entry.value.toString();
                        }
                      } else {
                        valueStr = entry.value.toString();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '$label: $valueStr',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }),

                const Divider(height: 30),

                const Text(
                  'Reviews:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Fetch and display all reviews for this submission
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future:
                        reviewsRef.orderBy('timestamp', descending: true).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No reviews yet'));
                      }

                      final reviewDocs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: reviewDocs.length,
                        itemBuilder: (context, index) {
                          final doc = reviewDocs[index];
                          final review = doc.data() as Map<String, dynamic>;
                          final reviewId = doc.id;

                          final subject = review['subject'] ?? 'No Subject';
                          final description =
                              review['description'] ?? 'No Description';
                          final sentBy = review['sentBy'] ?? 'Unknown';
                          final timestamp = review['timestamp'];

                          // Format review timestamp to readable format
                          final timeText =
                              (timestamp is Timestamp)
                                  ? _formatReadableTimestamp(
                                    timestamp.toDate().toLocal(),
                                  )
                                  : 'Unknown time';

                          return Card(
                            child: ListTile(
                              title: Text(subject),
                              subtitle: Text('$description\nSent By: $sentBy'),
                              trailing: Text(
                                timeText,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () async {
                                // When a review is tapped, go to detailed review screen
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/reviewDetail',
                                  arguments: {
                                    'userId': userId,
                                    'entryId': entryId,
                                    'reviewId': reviewId,
                                    'subject': subject,
                                    'description': description,
                                    'sentBy': sentBy,
                                    'timestamp': timeText,
                                    ...submissionFields, // also pass the submission data
                                  },
                                );

                                // If the review detail page returns something, refresh this page with new arguments
                                if (result != null && context.mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/review',
                                    arguments: result as Map<String, dynamic>,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Converts DateTime to a readable string like "Jun 11, 2025 – 3:45 PM"
  String _formatReadableTimestamp(DateTime dateTime) {
    return DateFormat('MMM d, y – h:mm a').format(dateTime);
  }
}
