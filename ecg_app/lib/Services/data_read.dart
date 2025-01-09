import 'package:csv/csv.dart';
import 'package:ecg_analyzer/Services/signal_processing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SignalRead {
  List<double>? normalizedData;


  Future<List<double>> loadEcgData(String fileLocation) async {
    try {
      List<double> data1 = await readCsv('assets/dataset/12_lead_ecg_test_$fileLocation.csv');
      data1.removeAt(0);

      SignalProcessor processor = SignalProcessor();

      int order = 5;
      double fs = 500.0;
      double lowcut = 0.5;
      double highcut = 50.0;

      List<double> filteredData = processor.bandpassFilter(data1 ?? [], order, lowcut, highcut, fs);

      List<double> normalizedData = processor.normalize(filteredData);

      return data1;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ecg data: $e');
      }
      return [];
    }
  }

  Future<List<double>> readCsv(String filePath) async {
    String csvContent = await rootBundle.loadString(filePath);
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvContent);
    List<double> data = [];
    for (int i = 0; i < csvTable[1].length; i++){
      if (csvTable[1][i].runtimeType == int){
        data.add(double.parse(csvTable[1][i].toString()));
      }
      else{
        data.add(csvTable[1][i]);
      }
    }
    return data;
  }
}



