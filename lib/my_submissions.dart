import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Stateless widget that displays all submissions made by the currently logged-in user
class MySubmissionsPage extends StatefulWidget {
  const MySubmissionsPage({super.key});

  @override
  State<MySubmissionsPage> createState() => _MySubmissionsPageState();
}

class _MySubmissionsPageState extends State<MySubmissionsPage> {
  final user = FirebaseAuth.instance.currentUser;

  List<QueryDocumentSnapshot> submissions = [];
  bool isLoading = false;
  bool _hasFetchedOnce = false; // Flag to prevent refetch on every visit

  Future<void> fetchSubmissions() async {
    if (user == null) return;

    setState(() => isLoading = true);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('entries')
            .orderBy('timestamp', descending: true)
            .get();

    setState(() {
      submissions = snapshot.docs;
      isLoading = false;
      _hasFetchedOnce = true; // Mark that initial fetch is done
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only fetch once, the first time the screen is shown
    if (!_hasFetchedOnce) {
      fetchSubmissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Submissions")),
        body: const Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Submissions',style: TextStyle(color: Colors.white,fontSize: 26),),backgroundColor: Colors.blue,),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchSubmissions, // Pull-to-refresh triggers fetch
                child:
                    submissions.isEmpty
                        ? const Center(child: Text("No submissions found."))
                        : ListView.builder(
                          itemCount: submissions.length,
                          itemBuilder: (context, index) {
                            final doc = submissions[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final timestampRaw = data['timestamp'];
                            DateTime? timestamp;
                            if (timestampRaw is Timestamp) {
                              timestamp = timestampRaw.toDate();
                            } else if (timestampRaw is String) {
                              timestamp = DateTime.tryParse(timestampRaw);
                            }

                            final canDelete =
                                timestamp != null &&
                                DateTime.now()
                                        .difference(timestamp)
                                        .inMinutes <=
                                    30;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              elevation: 3,
                              child: ListTile(
                                title: Text(data['name'] ?? 'No name'),
                                subtitle: Text(
                                  "Company: ${data['company'] ?? 'N/A'}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    if (canDelete)
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: Text(
                                                    "Delete Submission",
                                                  ),
                                                  content: Text(
                                                    "Are you sure you want to delete this submission?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .collection('entries')
                                                .doc(doc.id)
                                                .delete();

                                            // Refresh data manually after delete
                                            await fetchSubmissions();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Submission deleted',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/review',
                                    arguments: {
                                      ...data,
                                      'entryId': doc.id,
                                      'userId': user!.uid,
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
