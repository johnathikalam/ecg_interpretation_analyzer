import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;


class Prediction {
  Future<List<List<double>>> loadEcgData(String fileLocation) async{
    List<List<double>> fetchData = [];
    for (int i = 0; i < 12; i++){
      List<double> data = await readCsv('assets/dataset/12_lead_ecg_test_${fileLocation}.csv',i+1);
      fetchData.add(data);
    }
    return fetchData;
  }

  Future<List<List<double>>>predict(String fileLocation) async {
    List<List<double>> predictionData = [];

    for (int i = 0; i < 12; i++) {
      List<double> data = await readCsv('assets/dataset/12_lead_ecg_test_${fileLocation}.csv',i);
      Interpreter interpreter = await Interpreter.fromAsset('assets/models/tflite_lead_${i+1}.tflite');
      if (data.length != 1000) {
        print(data.length);
        print('Error: Input data must have exactly 1000 elements.');
        return [];
      }

      var inputArray = data.map((e) => e.toDouble()).toList();
      var reshapedInput = inputArray.reshape([1, 1000, 1]);

      var output = List.filled(5, 0.0).reshape([1, 5]);

      try {
        interpreter.run(reshapedInput, output);

        predictionData.add(output[0]);

      } catch (e) {
        print('Error running model: $e');
      }
    }
    return predictionData;
  }

  Future<List<double>>lead_one_predict(List<double> lead_one_data) async {
    // List<List<double>> predictionData = [];
    List<double> data = lead_one_data;
    Interpreter interpreter = await Interpreter.fromAsset('assets/models/tflite_lead_1.tflite');
    if (data.length != 1000) {
      print(data.length);
      print('Error: Input data must have exactly 1000 elements.');
      return [];
    }

    var inputArray = data.map((e) => e.toDouble()).toList();
    var reshapedInput = inputArray.reshape([1, 1000, 1]);

    var output = List.filled(5, 0.0).reshape([1, 5]);

    try {
      interpreter.run(reshapedInput, output);
    } catch (e) {
        print('Error running model: $e');
      }
    return output[0];
  }


  Future<List<double>> readCsv(String filePath, int i) async {
    String csvContent = await rootBundle.loadString(filePath);
    int count = 0;
    int firstIndex = 0;
      for (int j = 0; j <= csvContent.length; j++) {
        if (csvContent[j] == "\n") {
          firstIndex = j+1;
          count += 1;
          if(count >= i){
            break;
          }
        }
      }
    String content ='';
    for (int j = firstIndex; j < csvContent.length; j++){
      if(csvContent[j] != "\n"){
        content = content + csvContent[j];
      }
      else{
        break;
      }
    }

    List<dynamic> csvData = const CsvToListConverter().convert(content);
    List<double> data = [];
    for(int j = 0; j < csvData[0].length; j++){
      try {
        if (csvData[0][j].runtimeType == int) {
          data.add(double.parse(csvData[0][j].toString()));
        } else if (csvData[0][j].runtimeType == String) {

          data.add(double.parse(csvData[0][j].toString().trim()));
        } else {
          data.add(csvData[0][j]);
        }
      } catch (e) {
        print("Error parsing value ${csvData[j]}: $e");
      }
    }
    return data;
  }

  // Future<List<double>> readCsv(String filePath, int targetRow) async {
  //   String csvContent = await rootBundle.loadString(filePath);
  //   List<String> lines = csvContent.split('\n');
  //   if (targetRow >= lines.length) {
  //     throw Exception('Target row exceeds the number of lines in the CSV file.');
  //   }
  //   String targetContent = lines[targetRow];
  //   List<dynamic> csvData = const CsvToListConverter().convert(targetContent);
  //   List<double> data = [];
  //   for (var value in csvData[0]) {
  //     try {
  //       data.add(double.parse(value.toString().trim()));
  //     } catch (e) {
  //       print("Error parsing value $value: $e");
  //     }
  //   }
  //   return data;
  // }


  List<List<String>> getClassLabels(List<List<double>> predictions) {
    List<String> classLabels = ['Conduction Disturbance', 'Hypertrophy', 'Myocardial Infarction', 'Normal ECG', 'ST/T Change'];
    List<List<String>> results = [];

    for (var prediction in predictions) {
      List<String> classifiedLabels = [];
      for (int i = 0; i < prediction.length; i++) {
        if (prediction[i] > 0.5) {
          classifiedLabels.add(classLabels[i]);
        }
      }
      if (classifiedLabels.isEmpty) {
        classifiedLabels.add('Unclassified');
      }
      results.add(classifiedLabels);
    }

    return results;
  }

  List<String> getClassLabel(List<double> prediction) {
    List<String> classLabels = ['Conduction Disturbance', 'Hypertrophy', 'Myocardial Infarction', 'Normal ECG', 'ST/T Change'];

    List<String> classifiedLabels = [];
    for (int i = 0; i < prediction.length; i++) {
      if (prediction[i] > 0.5) {
        classifiedLabels.add(classLabels[i]);
      }
    }
    if (classifiedLabels.isEmpty) {
      classifiedLabels.add('Unclassified');
    }
    return classifiedLabels;
  }

}
