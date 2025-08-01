import 'package:flutter/material.dart';
import 'package:smart_texas_solar/constants.dart';
import 'package:smart_texas_solar/providers/combined_intervals_data_provider.dart';
import 'package:smart_texas_solar/widgets/intervals_chart.dart';

class EnergyStatsCard extends StatelessWidget {
  final CombinedIntervalsData data;
  final Function(SeriesType) toggleSeries;
  final Map<SeriesType, bool> seriesVisibilityState;

  const EnergyStatsCard(
      {super.key,
      required this.data,
      required this.toggleSeries,
      required this.seriesVisibilityState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    '${data.totalNet.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: data.totalNet >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Net Production',
                    style: TextStyle(fontSize: 24),
                  )
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => toggleSeries(SeriesType.totalProduction),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Icon(Icons.circle,
                        color:
                            seriesVisibilityState[SeriesType.totalProduction]!
                                ? kTotalProductionColor
                                : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Total Production - ${data.totalProduction.toStringAsFixed(1)} kWh',
                      style: TextStyle(
                          color:
                              seriesVisibilityState[SeriesType.totalProduction]!
                                  ? Colors.white
                                  : Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => toggleSeries(SeriesType.surplusProduction),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Icon(Icons.circle,
                        color:
                            seriesVisibilityState[SeriesType.surplusProduction]!
                                ? kSurplusProductionColor
                                : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Surplus Production - ${data.totalSurplus.toStringAsFixed(1)} kWh',
                      style: TextStyle(
                          color: seriesVisibilityState[
                                  SeriesType.surplusProduction]!
                              ? Colors.white
                              : Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => toggleSeries(SeriesType.totalConsumption),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Icon(Icons.circle,
                        color:
                            seriesVisibilityState[SeriesType.totalConsumption]!
                                ? kTotalConsumptionColor
                                : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Total Consumption - ${data.totalConsumption.toStringAsFixed(1)} kWh',
                      style: TextStyle(
                          color: seriesVisibilityState[
                                  SeriesType.totalConsumption]!
                              ? Colors.white
                              : Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => toggleSeries(SeriesType.gridConsumption),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Icon(Icons.circle,
                        color:
                            seriesVisibilityState[SeriesType.gridConsumption]!
                                ? kGridConsumptionColor
                                : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Grid Consumption - ${data.totalGrid.toStringAsFixed(1)} kWh',
                      style: TextStyle(
                          color:
                              seriesVisibilityState[SeriesType.gridConsumption]!
                                  ? Colors.white
                                  : Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => toggleSeries(SeriesType.cost),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Icon(Icons.remove,
                        color: seriesVisibilityState[SeriesType.cost]!
                            ? kCostColor
                            : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Cost - \$${data.totalCost.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: seriesVisibilityState[SeriesType.cost]!
                              ? Colors.white
                              : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
