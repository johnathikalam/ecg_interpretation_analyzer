
import 'package:flutter/material.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen(this.result, this.predictedResult, {super.key});
  final List<List<double>> result;
  final List<List<String>> predictedResult;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      appBar: AppBar(title: Text("Summary")),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: widget.predictedResult.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Lead ${index + 1} Prediction'),
            subtitle: Text(
                '${widget.predictedResult[index].toString()}\n ${widget.result[index].toString()}'),
          );
        },
      ),
    );
  }
}

