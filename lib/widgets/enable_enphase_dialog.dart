import 'package:flutter/material.dart';

class EnableEnphaseDialog extends StatelessWidget {
  const EnableEnphaseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Do you want to log in with an Enphase account to include solar production data?',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  decoration: TextDecoration.none),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                ElevatedButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ],
        ));
  }
}
