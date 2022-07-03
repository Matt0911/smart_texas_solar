/// Example of a numeric combo chart with two series rendered as bars, and a
/// third rendered as a line.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class LineBarComboChart extends StatelessWidget {
  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  const LineBarComboChart(this.seriesList, {this.animate = true});

  /// Creates a [LineChart] with sample data and no transition.
  // factory LineBarComboChart.withSampleData() {
  //   return LineBarComboChart(
  //     _createSampleData(),
  //     // Disable animations for image tests.
  //     animate: true,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      defaultRenderer: charts.LineRendererConfig(),
      customSeriesRenderers: [
        charts.BarRendererConfig(customRendererId: 'customBar')
      ],
    );
  }

  // /// Create one series with sample hard coded data.
  // static List<charts.Series<LinearSales, int>> _createSampleData() {
  //   final desktopSalesData = [
  //     LinearSales(0, 5),
  //     LinearSales(1, 25),
  //     LinearSales(2, 100),
  //     LinearSales(3, 75),
  //   ];

  //   final tableSalesData = [
  //     LinearSales(0, 5),
  //     LinearSales(1, 25),
  //     LinearSales(2, 100),
  //     LinearSales(3, 75),
  //   ];

  //   final mobileSalesData = [
  //     LinearSales(0, 10),
  //     LinearSales(1, 50),
  //     LinearSales(2, 200),
  //     LinearSales(3, 150),
  //   ];

  //   return [
  //     charts.Series<LinearSales, int>(

  //       id: 'Desktop',
  //       colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
  //       domainFn: (LinearSales sales, _) => sales.year,
  //       measureFn: (LinearSales sales, _) => sales.sales,
  //       data: desktopSalesData,
  //     )
  //       // Configure our custom bar renderer for this series.
  //       ..setAttribute(charts.rendererIdKey, 'customBar'),
  //     charts.Series<LinearSales, int>(
  //       id: 'Tablet',
  //       colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
  //       domainFn: (LinearSales sales, _) => sales.year,
  //       measureFn: (LinearSales sales, _) => sales.sales,
  //       data: tableSalesData,
  //     )
  //       // Configure our custom bar renderer for this series.
  //       ..setAttribute(charts.rendererIdKey, 'customBar'),
  //     charts.Series<LinearSales, int>(
  //         id: 'Mobile',
  //         colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
  //         domainFn: (LinearSales sales, _) => sales.year,
  //         measureFn: (LinearSales sales, _) => sales.sales,
  //         data: mobileSalesData),
  //   ];
  // }
}

/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}
