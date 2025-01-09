import 'package:ecg_analyzer/Screens/summary_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Services/prediction.dart';
import '../Utils/I18n.dart';
import '../Widgets/CustomIconButton.dart';
import '../Widgets/ecgChart.dart';
import 'home_screen.dart';


class GraphScreen extends StatefulWidget {
  const GraphScreen(this.selectedLocation, {super.key});
  final String selectedLocation;
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {

  var result;
  List<List<String>> predictedResult = [];
  List<List<FlSpot>> spots = List.generate(12, (_) => []);
  Prediction prediction = Prediction();

  @override
  void initState() {
    super.initState();
    fetchData();
    predict();
  }

  fetchData() async{
    var fetchData =  await prediction.loadEcgData(widget.selectedLocation);
    for (int i = 0; i < 12; i++){
      spots[i] = fetchData[i]
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList();
    }
    setState(() {
    });
  }

  predict() async {
    var res = await prediction.predict(widget.selectedLocation);
    var classes = prediction.getClassLabels(res);
    setState(() {
      predictedResult = classes;
      result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    var defaultLocale = Localizations.localeOf(context);
    I18n.setLocale(Locale(defaultLocale.languageCode));
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          //graph plotting
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: spots.isNotEmpty ?
            EcgChart(spots):
            Center(child:
            const CircularProgressIndicator(
              color: Colors.blue,
            )),
          ),

          CustomIconButton(
            onPressed: (){
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  const HomeScreen()),
              );
            },
            icon: const Icon(Icons.home_outlined,color: Colors.blue, size: 35,),
            bottom: 15,
            left: 10,
          ),

          result != null ? CustomIconButton(
            onPressed:  (){
              Navigator.push(context, MaterialPageRoute(builder: (context) =>   SummaryScreen(result, predictedResult)),              );
            },
            icon: const Icon(Icons.summarize_outlined,color: Colors.blue, size: 35,),
            right: 10,
            bottom: 15,
          ): Container()
        ],
      ),
    );
  }
}

