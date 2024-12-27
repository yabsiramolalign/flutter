import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tut4u/BookingPage.dart';
import 'package:tut4u/CustomerBookingsPage.dart';
import 'package:tut4u/TutorProfilePage.dart';
import 'package:tut4u/login.dart';

class CustomerDashboard extends StatefulWidget {
  final String name;

  CustomerDashboard({required this.name});

  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Stream<QuerySnapshot> getRecommendedTutors() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Tutor')
        // .orderBy('rating', descending: true)
        .limit(5)
        .snapshots();
  }

  Stream<QuerySnapshot> searchTutors(String query) {
    if (query.isEmpty) {
      return getRecommendedTutors();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Tutor')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }

  Stream<QuerySnapshot> getUpcomingBookings() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .snapshots();
  }

  void navigateToBookingPage(Map<String, dynamic> tutorData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(tutorData: tutorData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tut4U'),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () {
                // Navigate to login page
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text(
                'Login',
                style: TextStyle(color: Colors.black),
              ),
            ),
          if (user != null)
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {});
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome, ${widget.name}!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerBookingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Find a tutor...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 24),

            // Search Results or Recommended Tutors
            Text(
              _searchQuery.isEmpty ? 'Recommended Tutors' : 'Search Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: searchTutors(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No tutors found.'));
                }

                final tutors = snapshot.data!.docs;
                print(tutors[0].data());
                return SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tutors.length,
                    itemBuilder: (context, index) {
                      final tutor = tutors[index];
                      final tutorData = tutor.data() as Map<String, dynamic>;
                      return SizedBox(
                        width: 300,
                        height: 260,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TutorProfilePage(
                                  tutorId: tutor['id'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 16),
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  tutorData['profileImage'] ??
                                      'https://via.placeholder.com/150',
                                  height: 100,
                                  width: 300,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(width: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tutorData['name'] ?? 'No Name',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.orange, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '${tutorData['rating']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Expertise: ${tutorData['expertise']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                ElevatedButton(
                                  onPressed: () =>
                                      navigateToBookingPage(tutorData),
                                  child: Text('Book Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    minimumSize: Size(double.infinity,
                                        36), // Stretch button to full width
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 0, // Default to 'Home'
        onTap: (index) {
          // Handle navigation to other tabs
        },
      ),
    );
  }
}
