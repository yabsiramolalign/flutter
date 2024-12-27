import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorDashboard extends StatefulWidget {
  @override
  _TutorDashboardState createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  Future<Map<String, dynamic>?> fetchTutorProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateTutorProfile(Map<String, dynamic> updatedData) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(updatedData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully!')),
    );
    setState(() {});
  }

  Stream<QuerySnapshot> fetchTutorBookings() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: userId)
        .snapshots();
  }

  void showEditProfileDialog(Map<String, dynamic> profileData) {
    final expertiseController =
        TextEditingController(text: profileData['expertise']);
    final bioController = TextEditingController(text: profileData['bio']);
    final hourlyRateController =
        TextEditingController(text: profileData['hourlyRate']?.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: expertiseController,
                  decoration: InputDecoration(labelText: 'Expertise'),
                ),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(labelText: 'Bio'),
                ),
                TextField(
                  controller: hourlyRateController,
                  decoration: InputDecoration(labelText: 'Hourly Rate (\$)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = {
                  'expertise': expertiseController.text.trim(),
                  'bio': bioController.text.trim(),
                  'hourlyRate':
                      double.tryParse(hourlyRateController.text.trim()) ?? 0.0,
                };
                await updateTutorProfile(updatedData);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showEditFieldDialog(String fieldKey, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $fieldKey'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Enter your $fieldKey',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedValue = controller.text.trim();
                if (updatedValue.isNotEmpty) {
                  await updateTutorProfile({fieldKey: updatedValue});
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final profileData = await fetchTutorProfile();
              if (profileData != null) {
                showEditProfileDialog(profileData);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Unable to load profile for editing.')),
                );
              }
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchTutorProfile(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!profileSnapshot.hasData || profileSnapshot.data == null) {
            return Center(child: Text('Failed to load profile.'));
          }

          final tutorProfile = profileSnapshot.data!;
          final profileFields = [
            {'label': 'Expertise', 'key': 'expertise'},
            {'label': 'Bio', 'key': 'bio'},
            {'label': 'Hourly Rate', 'key': 'hourlyRate'},
            {'label': 'Rating', 'key': 'rating'}
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tutor Profile Section
              Container(
                color: Colors.blue.shade100,
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                          tutorProfile['profileImage'] ??
                              'https://via.placeholder.com/150'),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tutorProfile['name'],
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text('Expertise: ${tutorProfile['expertise']}'),
                        Text('Bio: ${tutorProfile['bio']}'),
                        Text(
                            'Hourly Rate: \$${tutorProfile['hourlyRate'] ?? 'N/A'}'),
                        Text('Rating: ${tutorProfile['rating']} ⭐'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Profile Details Section
              Expanded(
                child: ListView.builder(
                  itemCount: profileFields.length,
                  itemBuilder: (context, index) {
                    final field = profileFields[index];
                    final fieldKey = field['key'];
                    final fieldLabel = field['label'];
                    final fieldValue = tutorProfile[fieldKey] ?? 'Not defined';

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('$fieldLabel: $fieldValue'),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => showEditFieldDialog(
                              fieldKey!, fieldValue.toString()),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bookings Section
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: fetchTutorBookings(),
                  builder: (context, bookingsSnapshot) {
                    if (bookingsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!bookingsSnapshot.hasData ||
                        bookingsSnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No bookings available.'));
                    }

                    final bookings = bookingsSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final bookingData =
                            booking.data() as Map<String, dynamic>;

                        return Card(
                          margin: EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  bookingData['customerPhotoUrl'] ??
                                      'https://via.placeholder.com/150'),
                            ),
                            title: Text(bookingData['customerName']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${bookingData['date']}'),
                                Text('Time: ${bookingData['time']}'),
                                Text('Status: ${bookingData['status']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
