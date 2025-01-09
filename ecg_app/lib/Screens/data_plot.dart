import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Services/prediction.dart';
import '../Widgets/CustomIconButton.dart';

class DataPlot extends StatefulWidget {
  DataPlot(this.data, {super.key});
  final List<double> data;

  @override
  State<DataPlot> createState() => _DataPlotState();
}

class _DataPlotState extends State<DataPlot> {

  var result;
  List<String> predictedResult = [];
  List<FlSpot> dataPoints = [];

  @override
  void initState() {
    super.initState();
    // Convert data to FlSpot
    dataPoints = widget.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    predict();
  }

  predict() async {
    Prediction prediction = Prediction();
    var res = await prediction.lead_one_predict(widget.data);
    var classes = prediction.getClassLabel(res);
    setState(() {
      predictedResult = classes;
      result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Received ECG data'))),
      body: Stack(
        children: [
          Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: dataPoints,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    titlesData: const FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),

                    // Dynamically adjust the x-axis range to only show the last few points
                    minX: dataPoints.isEmpty ? 0 : dataPoints.first.x,
                    maxX: dataPoints.isEmpty ? 0 : dataPoints.last.x + 1,

                    // Set the y-axis range dynamically or fixed as per your data
                    maxY: widget.data.isEmpty ? 0 : widget.data.reduce((a, b) => a > b ? a : b) + .1,
                    minY: widget.data.isEmpty ? 0 : widget.data.reduce((a, b) => a < b ? a : b) - .1,
                  ),
                ),
              ),
            ),
          ],
        ),
          result != null ? CustomIconButton(
            onPressed:  (){
              _showBottomSheet(context, result, predictedResult);
            },
            icon: const Icon(Icons.summarize_outlined,color: Colors.blue, size: 35,),
            right: 10,
            bottom: 15,
          ) : Container()

        ],
      ),
    );
  }
}

void _showBottomSheet(BuildContext context, dynamic result, predictedResult) {
  List<String> classLabels = ['Conduction Disturbance', 'Hypertrophy', 'Myocardial Infarction', 'Normal ECG', 'ST/T Change'];
  List<String> classDiscription = [
    'The results show a possible delay or irregularity in the signals that control your heartbeat. This could cause symptoms like dizziness, fatigue, or irregular heartbeats. Please follow up with a cardiologist to evaluate this further and discuss potential treatment options.',
    'The analysis suggests that your heart muscle may be thicker than normal. This could be due to high blood pressure or other conditions that make your heart work harder. It’s important to monitor this closely with your doctor and take steps to manage your heart health.',
    'The analysis suggests a possible heart attack. This happens when blood flow to your heart is blocked, which can damage the heart muscle. You may experience symptoms like chest pain, shortness of breath, or discomfort in your arms or back. Please seek immediate medical attention to get the necessary treatment.',
    'Your ECG looks normal, which means your heart is beating regularly, and the electrical signals in your heart are functioning properly. There are no signs of any abnormalities. Keep up with a healthy lifestyle to maintain good heart health!',
    'There are some changes in your ECG that could indicate reduced blood flow to your heart or an early sign of a heart condition. It’s important to consult a doctor to determine the cause and take necessary steps to protect your heart.'
  ];

  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(predictedResult[0].toString()),
              SizedBox(height: 5),
              Text(classLabels.indexOf(predictedResult[0]) == -1
                  ? "Please ensure the ECG leads are placed correctly to obtain an accurate signal."
                  : classDiscription[classLabels.indexOf(predictedResult[0])]),
              // Text(result.toString()),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
