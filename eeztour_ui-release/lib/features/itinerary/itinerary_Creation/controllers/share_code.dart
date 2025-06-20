import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:clipboard/clipboard.dart';

import '../../../../common/config.dart';

Future<void> fetchAndShowShareCode(BuildContext context, int itineraryId) async {
  final url = Uri.parse('$baseUrl/itinerary/get_share_code/$itineraryId');

  try {
    final response = await http.get(url, headers: {
      'accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);


      // Copy to clipboard
      FlutterClipboard.copy(data);

      // Show popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Share Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your share code is:'),
              SizedBox(height: 10),
              SelectableText(
                data,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              SizedBox(height: 10),
              Text('(Automatically copied!)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
        ),
      );
    } else {
      throw Exception('Failed to fetch share code: ${response.statusCode}');
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          )
        ],
      ),
    );
  }
}
