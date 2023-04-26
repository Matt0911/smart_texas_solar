import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/combined_interval.dart';

final _formatter = DateFormat('h:mm');
final _formatterEnd = DateFormat('h:mm a');
final _formatterDate = DateFormat('MMM d');

const TextStyle kTooltipTitleStyle = TextStyle(
  color: Colors.black,
  fontSize: 16,
  decoration: TextDecoration.underline,
);
const TextStyle kTooltipTextStyle = TextStyle(color: Colors.black);

class IntervalsChart extends StatefulWidget {
  final List<CombinedInterval> intervalsData;
  const IntervalsChart({super.key, required this.intervalsData});

  @override
  State<IntervalsChart> createState() => _IntervalsChartState();
}

class _IntervalsChartState extends State<IntervalsChart> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    _tooltipBehavior = TooltipBehavior(
        enable: true,
        shared: true,
        duration: 10000,
        tooltipPosition: TooltipPosition.pointer,
        builder: ((data, point, series, pointIndex, seriesIndex) {
          CombinedInterval interval = data;
          var diffHours =
              interval.endTime.difference(interval.startTime).inHours;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  diffHours < 24
                      ? '${_formatter.format(interval.startTime)} - ${_formatterEnd.format(interval.endTime)}'
                      : _formatterDate.format(interval.startTime),
                  style: kTooltipTitleStyle,
                ),
                const SizedBox(
                  height: 8,
                  width: 1,
                ),
                Table(
                  columnWidths: const {
                    0: FixedColumnWidth(110),
                    1: IntrinsicColumnWidth()
                  },
                  children: [
                    _getTooltipRow(
                      text: 'Production',
                      value: interval.kwhSolarProduction,
                    ),
                    _getTooltipRow(
                      text: 'Consumption',
                      value: interval.kwhTotalConsumption,
                    ),
                    _getTooltipRow(
                      text: 'Net',
                      value: interval.kwhSolarProduction -
                          interval.kwhTotalConsumption,
                    ),
                    _getTooltipRow(
                      text: 'Cost',
                      value: interval.cost ?? 0,
                      unit: '\$',
                      unitBefore: true,
                    ),
                  ],
                )
              ],
            ),
          );
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      legend: Legend(
        isVisible: true,
        itemPadding: 20,
        iconHeight: 20,
        iconWidth: 20,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      primaryXAxis: DateTimeAxis(),
      primaryYAxis: NumericAxis(title: AxisTitle(text: 'kWh')),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        zoomMode: ZoomMode.x,
      ),
      axes: [
        NumericAxis(
            name: 'yAxis2',
            labelFormat: '\${value}',
            decimalPlaces: 4,
            opposedPosition: true,
            majorGridLines:
                const MajorGridLines(color: Color.fromARGB(255, 0, 38, 70)))
      ],
      tooltipBehavior: _tooltipBehavior,
      series: <ChartSeries>[
        AreaSeries<CombinedInterval, DateTime>(
          name: 'Production',
          dataSource: widget.intervalsData,
          xValueMapper: (data, _) => data.startTime,
          yValueMapper: (data, _) => data.kwhSolarProduction,
          color: Colors.green.shade300,
          enableTooltip: true,
        ),
        AreaSeries<CombinedInterval, DateTime>(
          name: 'Surplus',
          dataSource: widget.intervalsData,
          xValueMapper: (data, _) => data.startTime,
          yValueMapper: (data, _) => data.kwhSurplusGeneration,
          color: Colors.green.shade500,
          enableTooltip: true,
        ),
        AreaSeries<CombinedInterval, DateTime>(
          name: 'Consumption Total',
          dataSource: widget.intervalsData,
          xValueMapper: (data, _) => data.startTime,
          yValueMapper: (data, _) => data.kwhTotalConsumption,
          color: Colors.red.shade300,
          opacity: 0.6,
          enableTooltip: true,
          animationDelay: 500,
        ),
        AreaSeries<CombinedInterval, DateTime>(
          name: 'Consumption Grid',
          dataSource: widget.intervalsData,
          xValueMapper: (data, _) => data.startTime,
          yValueMapper: (data, _) => data.kwhGridConsumption,
          color: Colors.red.shade500,
          opacity: 0.4,
          enableTooltip: true,
          animationDelay: 500,
        ),
        LineSeries<CombinedInterval, DateTime>(
          name: 'Cost',
          dataSource: widget.intervalsData,
          xValueMapper: (data, _) => data.startTime,
          yValueMapper: (data, _) => data.cost,
          color: Colors.blue.shade800,
          enableTooltip: true,
          yAxisName: 'yAxis2',
          width: .75,
          animationDelay: 1000,
        ),
      ],
    );
  }
}

TableRow _getTooltipRow({
  required String text,
  required num value,
  String unit = 'kWh',
  bool unitBefore = false,
}) =>
    TableRow(
      children: [
        Text(
          '$text:',
          style: kTooltipTextStyle,
        ),
        Container(
          alignment: Alignment.centerRight,
          child: Text(
            unitBefore
                ? '$unit${value.toStringAsFixed(3)}'
                : '${value.toStringAsFixed(3)} $unit',
            style: kTooltipTextStyle,
          ),
        ),
      ],
    );
