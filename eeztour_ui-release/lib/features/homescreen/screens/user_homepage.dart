import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../common/config.dart';
import '../../itinerary/itinerary_Menu/screens/itineraryMenu.dart';

class ShareCodeScreen extends StatefulWidget {
  const ShareCodeScreen({Key? key}) : super(key: key);

  @override
  State<ShareCodeScreen> createState() => _ShareCodeScreenState();
}

class _ShareCodeScreenState extends State<ShareCodeScreen> {
  final TextEditingController _shareCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;



  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  Future<int?> _getItineraryIdFromShareCode(String shareCode) async {
    print("sharecode: $shareCode");
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/itinerary/shared_itinerary_id/$shareCode'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body); // This is just an int
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Share code not found');
      } else {
        throw Exception('Failed to fetch itinerary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> _submitShareCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String shareCode = _shareCodeController.text.trim();
        int? itineraryId = (await _getItineraryIdFromShareCode(shareCode)) as int?;

        if (itineraryId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItineraryMenu(id: itineraryId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid share code. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print(e);
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Share Code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.share,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter Share Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the share code to access the itinerary',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _shareCodeController,
                decoration: const InputDecoration(
                  labelText: 'Share Code',
                  hintText: 'Enter share code here',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a share code';
                  }
                  if (value.trim().length < 3) {
                    return 'Share code must be at least 3 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitShareCode(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitShareCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Access Itinerary',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

