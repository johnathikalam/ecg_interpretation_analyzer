import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'expanded_chart.dart';

class LineChartWidget extends StatelessWidget {
  final List<FlSpot> spots;
  final int index;

  LineChartWidget({required this.spots , required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute( builder: (context) => DetailedLineChart(spots: spots, index: index),
        ),);},
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 2,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: false), // Hide dots
                  ),
                ],
                borderData: FlBorderData(show: true),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(enabled: false),
              ),
            ),
          ),
          SizedBox(height: 5,),
          Text("Lead ${index + 1}"),
        ],
      ),
    );
  }
}
