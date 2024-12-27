import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerBookingsPage extends StatefulWidget {
  @override
  _CustomerBookingsPageState createState() => _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends State<CustomerBookingsPage> {
  Stream<QuerySnapshot> getCustomerBookings() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated to $newStatus.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking canceled successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getCustomerBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No bookings found.'));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final bookingData = booking.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                        bookingData['tutorPhotoUrl'] ??
                            'https://via.placeholder.com/150'),
                  ),
                  title: Text(bookingData['tutorName'] ?? 'Tutor Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${bookingData['date']}'),
                      Text('Time: ${bookingData['time']}'),
                      Text('Status: ${bookingData['status']}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Reschedule') {
                        // Logic for rescheduling
                        showDialog(
                          context: context,
                          builder: (context) {
                            TextEditingController newDateController =
                                TextEditingController();
                            TextEditingController newTimeController =
                                TextEditingController();

                            return AlertDialog(
                              title: Text('Reschedule Booking'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: newDateController,
                                    decoration: InputDecoration(
                                        labelText:
                                            'New Date (e.g., 2024-12-30)'),
                                  ),
                                  TextField(
                                    controller: newTimeController,
                                    decoration: InputDecoration(
                                        labelText: 'New Time (e.g., 10:00 AM)'),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (newDateController.text.isNotEmpty &&
                                        newTimeController.text.isNotEmpty) {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('bookings')
                                            .doc(booking.id)
                                            .update({
                                          'date': newDateController.text.trim(),
                                          'time': newTimeController.text.trim(),
                                          'status': 'rescheduled',
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Booking rescheduled successfully.')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Failed to reschedule booking: $e')),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Please provide both date and time.')),
                                      );
                                    }
                                  },
                                  child: Text('Reschedule'),
                                ),
                              ],
                            );
                          },
                        );
                      } else if (value == 'Cancel') {
                        cancelBooking(booking.id);
                      } else if (value == 'Confirm') {
                        updateBookingStatus(booking.id, 'confirmed');
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'Confirm', child: Text('Confirm Booking')),
                      PopupMenuItem(
                          value: 'Reschedule', child: Text('Reschedule')),
                      PopupMenuItem(
                          value: 'Cancel', child: Text('Cancel Booking')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
