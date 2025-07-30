import 'package:smart_texas_solar/constants.dart';
import 'package:smart_texas_solar/providers/combined_intervals_data_provider.dart';
import 'package:smart_texas_solar/widgets/energy_stats_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/combined_interval.dart';
import 'dart:math';

final _formatter = DateFormat('h:mm');
final _formatterEnd = DateFormat('h:mm a');
final _formatterDate = DateFormat('MMM d');

const TextStyle kTooltipTitleStyle = TextStyle(
  color: Colors.black,
  fontSize: 16,
  decoration: TextDecoration.underline,
);
const TextStyle kTooltipTextStyle = TextStyle(color: Colors.black);

enum SeriesType {
  totalProduction,
  surplusProduction,
  totalConsumption,
  gridConsumption,
  cost,
}

class IntervalsChart extends StatefulWidget {
  final CombinedIntervalsData combinedIntervalsData;
  const IntervalsChart({super.key, required this.combinedIntervalsData});

  @override
  State<IntervalsChart> createState() => _IntervalsChartState();
}

class _IntervalsChartState extends State<IntervalsChart> {
  late TooltipBehavior _tooltipBehavior;
  Map<SeriesType, bool> seriesVisibilityState = {
    SeriesType.totalProduction: true,
    SeriesType.surplusProduction: true,
    SeriesType.totalConsumption: true,
    SeriesType.gridConsumption: true,
    SeriesType.cost: true,
  };

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

  toggleSeriesVisibility(SeriesType type) {
    setState(() {
      seriesVisibilityState[type] = !seriesVisibilityState[type]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => Flex(
          direction: orientation == Orientation.portrait
              ? Axis.vertical
              : Axis.horizontal,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnergyStatsCard(
              data: widget.combinedIntervalsData,
              toggleSeries: toggleSeriesVisibility,
              seriesVisibilityState: seriesVisibilityState,
            ),
            Expanded(
              child: SfCartesianChart(
                // legend: Legend(
                //   initialIsVisible: true, true,
                // itemPadding: 20,
                //   iconHeight: 20,
                //   iconWidth: 20,
                //   width: '100%',
                //   // overflowMode: LegendItemOverflowMode.wrap,
                //   // position: LegendPosition.left,
                //   orientation: LegendItemOrientation.vertical,
                //   legendItemBuilder: (legendText, series, point, seriesIndex) =>
                //       Row(mainAxisSize: MainAxisSize.max, children: [
                //     Text('First'),
                //     Text('Second'),
                //     Text('Thrid'),
                //   ]),
                // ),
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
                      majorGridLines: const MajorGridLines(
                          color: Color.fromARGB(255, 0, 38, 70)))
                ],
                tooltipBehavior: _tooltipBehavior,
                series: <CartesianSeries>[
                  AreaSeries<CombinedInterval, DateTime>(
                    name: 'Total Production',
                    dataSource: widget.combinedIntervalsData.intervalsList,
                    xValueMapper: (data, _) => data.startTime,
                    yValueMapper: (data, _) => data.kwhSolarProduction,
                    color: kTotalProductionColor,
                    enableTooltip: true,
                    initialIsVisible: true,
                    // seriesVisibilityState[SeriesType.totalProduction],
                  ),
                  AreaSeries<CombinedInterval, DateTime>(
                    name: 'Surplus Production',
                    dataSource: widget.combinedIntervalsData.intervalsList,
                    xValueMapper: (data, _) => data.startTime,
                    yValueMapper: (data, _) => data.kwhSurplusGeneration,
                    color: kSurplusProductionColor,
                    enableTooltip: true,
                    initialIsVisible: true,
                    // seriesVisibilityState[SeriesType.surplusProduction],
                  ),
                  AreaSeries<CombinedInterval, DateTime>(
                    name: 'Total Consumption',
                    dataSource: widget.combinedIntervalsData.intervalsList,
                    xValueMapper: (data, _) => data.startTime,
                    yValueMapper: (data, _) => max(data.kwhTotalConsumption, 0),
                    color: kTotalConsumptionColor,
                    opacity: 0.6,
                    enableTooltip: true,
                    animationDelay: 500,
                    initialIsVisible: true,
                    // seriesVisibilityState[SeriesType.totalConsumption],
                  ),
                  AreaSeries<CombinedInterval, DateTime>(
                    name: 'Grid Consumption',
                    dataSource: widget.combinedIntervalsData.intervalsList,
                    xValueMapper: (data, _) => data.startTime,
                    yValueMapper: (data, _) => data.kwhGridConsumption,
                    color: kGridConsumptionColor,
                    opacity: 0.4,
                    enableTooltip: true,
                    animationDelay: 500,
                    initialIsVisible: true,
                    // seriesVisibilityState[SeriesType.gridConsumption],
                  ),
                  LineSeries<CombinedInterval, DateTime>(
                    name: 'Cost',
                    dataSource: widget.combinedIntervalsData.intervalsList,
                    xValueMapper: (data, _) => data.startTime,
                    yValueMapper: (data, _) => data.cost,
                    color: kCostColor,
                    enableTooltip: true,
                    yAxisName: 'yAxis2',
                    width: .75,
                    animationDelay: 1000,
                    initialIsVisible: true,
                    // seriesVisibilityState[SeriesType.cost],
                  ),
                  // ),
                ],
              ),
            ),
          ]),
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
