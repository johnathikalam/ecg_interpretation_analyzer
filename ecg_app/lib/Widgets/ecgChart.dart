import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import '../Utils/colors.dart';
import 'chart.dart';


class EcgChart extends StatefulWidget {
  const EcgChart(this.spots,{super.key});
  final List<List<FlSpot>> spots;
  @override
  State<EcgChart> createState() => _EcgChartState();
}

class _EcgChartState extends State<EcgChart> {

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ), itemCount: widget.spots.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.spots.isNotEmpty ? LineChartWidget(spots: widget.spots[index], index: index,) :
          CircularProgressIndicator(),
        );
      },
    );
  }
}