import 'package:flutter/material.dart';

class AsyncButton extends StatefulWidget {
  final Future Function() onPressed;
  final IconData icon;
  final String label;
  const AsyncButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool loading = false;

  void onPressed() {
    setState(() {
      loading = true;
      setLoadingToFalse() {
        setState(() {
          loading = false;
        });
      }

      widget.onPressed().then((value) => setLoadingToFalse()).catchError((e) {
        print(e);
        setLoadingToFalse();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(widget.icon),
      label: Text(loading ? 'Loading...' : widget.label),
    );
  }
}
