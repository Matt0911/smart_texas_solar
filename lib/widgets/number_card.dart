import 'package:flutter/material.dart';

class NumberCard extends StatelessWidget {
  final String title;
  final num value;
  final String? valueUnits;
  final Color valueColor;
  final int decimalPlaces;

  const NumberCard({
    super.key,
    required this.title,
    required this.value,
    this.valueUnits,
    required this.valueColor,
    this.decimalPlaces = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${value.toStringAsFixed(decimalPlaces)} ${valueUnits ?? ''}',
                style: TextStyle(fontSize: 20, color: valueColor),
              )
            ],
          ),
        ),
      ),
    );
  }
}
