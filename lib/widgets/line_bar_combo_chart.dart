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
      primaryMeasureAxis: const charts.NumericAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
              lineStyle: charts.LineStyleSpec(
                  color: charts.Color(r: 100, g: 100, b: 100)),
              labelStyle: charts.TextStyleSpec(
                  color: charts.Color(r: 255, g: 255, b: 255)))),
      domainAxis: const charts.DateTimeAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
              lineStyle: charts.LineStyleSpec(
                  color: charts.Color(r: 100, g: 100, b: 100)),
              labelStyle: charts.TextStyleSpec(
                  color: charts.Color(r: 255, g: 255, b: 255)))),
    );
  }
}

/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}
