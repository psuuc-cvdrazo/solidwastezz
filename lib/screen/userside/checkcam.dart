import 'dart:async'; // Import this for Timer
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

class CheckTimePage extends StatefulWidget {
  @override
  _CheckTimePageState createState() => _CheckTimePageState();
}

class _CheckTimePageState extends State<CheckTimePage> {
  final _supabase = SupabaseClient(
    'https://uiciowpyxfawjvaddivu.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVpY2lvd3B5eGZhd2p2YWRkaXZ1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNzE0MDQyMCwiZXhwIjoyMDQyNzE2NDIwfQ.kR8PsVyqtW0QTJoFjFq6aiXU-iq0y3alXfJQIRMVgBw',
  );
  List<Map<String, dynamic>> _collectionPoints = [];
  String _selectedCollectionPoint = '';
  String _latestImageUrl = '';
  bool _loadingImage = false;
  Timer? _timer; // Timer instance
  String _latestImageDate = '';

  @override
  void initState() {
    super.initState();
    _populateDropdown();
    _startTimer(); // Start the timer
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }
void _showSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ),
  );
}

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_selectedCollectionPoint.isNotEmpty) {
        _loadLatestImage(_selectedCollectionPoint);
      }
    });
  }

  Future<void> _requestEmpty() async {
  if (_selectedCollectionPoint.isEmpty) {
    _showSnackbar('No collection point selected.');
    return;
  }

  try {
    // Fetch the latest image for the selected collection point
    final latestImageResponse = await _supabase
        .from('images')
        .select('image_url, created_at')
        .eq('cp_id', _selectedCollectionPoint)
        .order('created_at', ascending: false)
        .limit(1);

    if (latestImageResponse.isNotEmpty) {
      final latestImage = latestImageResponse[0];
      final latestImageUrl = latestImage['image_url'];
      final createdAt = DateTime.now().toIso8601String(); // Current timestamp

      // Insert the details into cp_approval
      final approvalResponse = await _supabase.from('cp_approval').insert([
        {
          'image_url': latestImageUrl,
          'status': 'full',
          'created_at': createdAt,
          'cp_name': _selectedCollectionPoint,
        }
      ]);

      if (approvalResponse.isNotEmpty) {
        _showSnackbar('Request Empty successfully added to cp_approval.');
      } else {
        _showSnackbar('Error inserting into cp_approval.');
      }
    } else {
      _showSnackbar('No image found for the selected collection point.');
    }
  } catch (error) {
    print('Error: $error');
    _showSnackbar('An error occurred. Please try again.');
  }
}


  Future<void> _populateDropdown() async {
    // Initial loading of collection points
    final collectionPointsResponse = await _supabase
        .from('collection_point')
        .select('cp_name, cp_address')
        .eq('cp_add_state', 'yes')
        .order('cp_name', ascending: true);

    if (collectionPointsResponse.isNotEmpty) {
      setState(() {
        _collectionPoints =
            List<Map<String, dynamic>>.from(collectionPointsResponse);
        _selectedCollectionPoint =
            _collectionPoints.isNotEmpty ? _collectionPoints[0]['cp_name'] : '';
      });
      _loadLatestImage(_selectedCollectionPoint);
    } else {
      print('No collection points found.');
    }
  }

Future<void> _loadLatestImage(String cpName) async {
  setState(() {
    _loadingImage = true; // Show loading GIF
  });

  final latestImageResponse = await _supabase
      .from('images')
      .select('image_url, created_at')
      .eq('cp_id', cpName)
      .order('created_at', ascending: false)
      .limit(1);

  if (latestImageResponse.isNotEmpty) {
    final latestImage = latestImageResponse[0];
    final createdAt = DateTime.parse(latestImage['created_at']);
    final formattedDate = _formatDate(createdAt);

    if (mounted) { // Check if the widget is still mounted before calling setState
      setState(() {
        _latestImageUrl = latestImage['image_url'];
        _latestImageDate = formattedDate; // Save the formatted date
      });
    }
  }

  // Wait for 10 seconds before stopping the loading state
  await Future.delayed(Duration(seconds: 10));

  if (mounted) { // Check again before calling setState
    setState(() {
      _loadingImage = false; // Hide loading GIF after 10 seconds
    });
  }
}



  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year} ${_formatTime(date)}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  Future<void> _uploadRequest() async {
    // Cancel the existing timer and start a new one
    _timer?.cancel();
    _startTimer();

    setState(() {
      _loadingImage = true; // Show loading GIF while processing the request
    });

    final response = await _supabase.from('controls').insert([
      {'who': 'live request $_selectedCollectionPoint'}
    ]);

    if (response.isNotEmpty) {
      print('Request uploaded successfully');
      _loadLatestImage(_selectedCollectionPoint); // Reload the latest image
    } else {
      print('Error uploading request');
    }

    setState(() {
      _loadingImage = false; // Hide loading GIF after the request
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Check Status'),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Container
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: _loadingImage
                  ? Container(
                      height: 300,
                      child: Center(
                        child: Image.asset(
                          'assets/img/logspin.gif',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_latestImageUrl.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullImageView(
                                    imageUrl: _latestImageUrl,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(_latestImageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (_latestImageDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _latestImageDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            SizedBox(height: 20),
      
            // Dropdown Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: DropdownButton<String>(
                  value: _selectedCollectionPoint.isEmpty
                      ? null
                      : _selectedCollectionPoint,
                  onChanged: (value) {
                    setState(() {
                      _selectedCollectionPoint = value!;
                      _loadLatestImage(value);
                    });
                  },
                  hint: Text(
                    'Select Collection Point',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  isExpanded: true,
                  underline: SizedBox(),
                  items: _collectionPoints.map((point) {
                    return DropdownMenuItem<String>(
                      value: point['cp_name'],
                      child: Text(
                        '${point['cp_name']} (${point['cp_address']})',
                        style: TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
      
            // Buttons Section
            Center(
              child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
      ElevatedButton.icon(
        onPressed: () {
          _showQuickAlert(
            context,
            title: 'Check',
            message: 'Do you want to check?',
            onConfirm: () {
              Navigator.of(context).pop(); // Close alert
              _uploadRequest(); // Perform Check action
            },
          );
        },
        icon: Icon(Icons.search,color: Colors.white,),
        label: Text('Check',style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Set the button color to blue
         
        ),
      ),
      SizedBox(height: 10),
      ElevatedButton.icon(
        onPressed: () {
          _showQuickAlert(
            context,
            title: 'Request Empty',
            message: 'Do you want to request empty?',
            onConfirm: () {
              Navigator.of(context).pop(); // Close alert
              _requestEmpty(); // Perform Request Empty action
            },
          );
        },
        icon: Icon(Icons.clear_outlined,color: Colors.red,),
        label: Text('Request Empty',style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
         backgroundColor: const Color(0xFF587F38),
         
        ),
      ),
        ],
      )
      
            ),
          ],
        ),
      ),
    ),
  );
}

void _showQuickAlert(BuildContext context,
    {required String title,
    required String message,
    required VoidCallback onConfirm}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 123, 20, 20), // Set the button color to blue
                     
                    ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('No',style: TextStyle(color: Colors.white),),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 18, 131, 10), // Set the button color to blue
                    
                    ),
                onPressed: onConfirm,
                child: Text('Yes',style: TextStyle(color: Colors.white),),
                
              ),
            ],
          ),
        ],
      );
    },
  );
}

}


class FullImageView extends StatelessWidget {
  final String imageUrl;

  const FullImageView({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Image View'),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
