import 'package:flutter/material.dart';

class ContinueButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isEnabled;

  const ContinueButton({
    Key? key,
    required this.onPressed,
    this.label = 'Continue',
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // Adjust if you want a taller or shorter button
      child: ElevatedButton(
        // If `isEnabled` is false, onPressed will be null, disabling the button.
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFA3C4C), // Example red color
          disabledBackgroundColor: Colors.grey,      // Disabled button color
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

// Example of usage with the button positioned at the bottom
class MyScreenWithStickyButton extends StatelessWidget {
  const MyScreenWithStickyButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Your main content goes here
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Your scrollable content
                      // ...
                    ],
                  ),
                ),
              ),
            ),
            
            // Button container with padding at the bottom
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ContinueButton(
                onPressed: () {
                  // Your action here
                },
                label: 'Continue',
                isEnabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}