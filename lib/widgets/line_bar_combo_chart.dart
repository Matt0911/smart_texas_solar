/// Example of a numeric combo chart with two series rendered as bars, and a
/// third rendered as a line.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/combined_interval.dart';

final _formatter = DateFormat('H:mm');
final _formatterDate = DateFormat('MMM d');

class LineBarComboChart extends StatelessWidget {
  final List<charts.Series<CombinedInterval, DateTime>> seriesList;
  final bool animate;

  const LineBarComboChart(this.seriesList, {super.key, this.animate = true});

  List<charts.TickSpec<DateTime>> getTicks(List<CombinedInterval> data) {
    List<CombinedInterval> short;
    int diff = data.last.endTime.difference(data.first.startTime).inDays;
    if (diff <= 1) {
      short = data
          .where((element) =>
              element.startTime.minute == 0 && element.startTime.hour % 4 == 0)
          .toList();
    } else if (diff == 2) {
      short = data
          .where((element) =>
              element.startTime.minute == 0 && element.startTime.hour % 6 == 0)
          .toList();
    } else {
      var temp = data
          .where((element) =>
              element.startTime.minute == 0 && element.startTime.hour == 0)
          .toList();
      int step = (diff / 10).ceil();
      short = [];
      for (int i = 0; i < temp.length; i += step) {
        short.add(temp[i]);
      }
    }

    return short
        .map(
          (e) => charts.TickSpec<DateTime>(e.startTime),
        )
        .toList();
  }

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
        charts.BarRendererConfig(
            customRendererId: 'customBar',
            groupingType: charts.BarGroupingType.stacked)
      ],
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec:
            charts.BasicNumericTickProviderSpec(dataIsInWholeNumbers: false),
        renderSpec: charts.GridlineRendererSpec(
          lineStyle: charts.LineStyleSpec(
            color: charts.Color(r: 100, g: 100, b: 100),
          ),
          labelStyle: charts.TextStyleSpec(
            color: charts.Color(r: 255, g: 255, b: 255),
          ),
        ),
      ),
      domainAxis: charts.DateTimeAxisSpec(
        tickFormatterSpec: charts.BasicDateTimeTickFormatterSpec((datetime) =>
            datetime.hour == 0 && datetime.minute == 0
                ? _formatterDate.format(datetime)
                : _formatter.format(datetime)),
        tickProviderSpec: charts.StaticDateTimeTickProviderSpec(
          getTicks(seriesList[0].data),
        ),
        renderSpec: const charts.GridlineRendererSpec(
          lineStyle:
              charts.LineStyleSpec(color: charts.Color(r: 100, g: 100, b: 100)),
          labelStyle: charts.TextStyleSpec(
            color: charts.Color(r: 255, g: 255, b: 255),
          ),
          labelRotation: 45,
        ),
      ),
    );
  }
}
