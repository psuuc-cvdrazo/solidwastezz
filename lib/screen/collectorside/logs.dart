import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogScreen extends StatefulWidget {
  LogScreen({Key? key}) : super(key: key);

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> feedbackList = [];
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown date';
    final DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    fetchFeedback().then((data) {
      setState(() {
        feedbackList = data;
      });
    }).catchError((e) {
      print('Failed to load feedback: $e');
    });
  }

  Future<List<dynamic>> fetchFeedback() async {
    try {
      final response = await supabase
          .from('userfeedback')
          .select('id, created_at, username, email, feedback, img_fb')
          .order('created_at', ascending: false);

      if (response != null) {
        return response as List<dynamic>;
      } else {
        throw Exception('No feedback found.');
      }
    } catch (e) {
      print('Error fetching feedback: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Collection points of All Barangay',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 47, 61, 2),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Color(0xFF1B3313),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/img/logspin.gif',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collector Name:',
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'username',
                            style: TextStyle(
                              fontSize: 22.0,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Collector',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.green.shade100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.0),
              Text(
                'Logs Notification',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFEDF0DC),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Time and Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                          Text(
                            'Image',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: Colors.black38), // Divider for separation
                    Column(
                      children: feedbackList.map((feedback) {
                        return Column(
                          children: [
                            _buildLogRow('View', feedback),
                            Divider(
                                color: Colors
                                    .black38), // Divider for feedback items
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogRow(String imageSource, Map<String, dynamic> feedback) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feedback['feedback'] ?? 'No feedback provided',
              style: TextStyle(fontSize: 14.0, color: Colors.black),
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => _buildFeedbackDialog(feedback),
                );
              },
              child: Text(
                imageSource,
                style: TextStyle(fontSize: 14.0, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackDialog(Map<String, dynamic> feedback) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(16.0),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (feedback['img_fb'] != null)
                  Image.network(
                    feedback['img_fb'],
                    fit: BoxFit.cover,
                    height: 200,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Image.asset(
                          'assets/img/logspin.gif',
                          height: 300,
                          width: 300,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/img/logspin.gif',
                        height: 200,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.0),
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.feedback, color: Colors.green),
                          SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              feedback['feedback'] ?? 'No feedback provided',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.0),
                      Divider(color: Colors.grey[300]),
                      SizedBox(height: 12.0),
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8.0),
                          Text(
                            'Reported by:',
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            feedback['username'] ?? 'Unknown',
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.black54),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.orange),
                          SizedBox(width: 8.0),
                          Text(
                            'Email:',
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              feedback['email'] ?? 'No email provided',
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.purple),
                          SizedBox(width: 8.0),
                          Text(
                            'Date:',
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            _formatDateTime(feedback['created_at']),
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
