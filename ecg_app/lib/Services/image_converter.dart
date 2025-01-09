import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math.dart' as vmath;
import 'package:csv/csv.dart';

class Axes {
  final List<double> px;
  final List<double> py;
  final int dimensions;
  final List<String> dp;
  final List<String> labels;

  Axes({required this.px, required this.py, required this.dimensions, required this.dp, required this.labels});

  List<double> pixelToData(double pxi, double pyi, vmath.Matrix2 aMat, List<double> cVec,
      {bool isLogScaleX = false, bool isLogScaleXNegative = false,
        bool isLogScaleY = false, bool isLogScaleYNegative = false}) {
    double xp = pxi;
    double yp = pyi;

    // Apply the affine transformation

    vmath.Vector2 datVec = aMat.transformed(vmath.Vector2(xp, yp));
    datVec.x += cVec[0];
    datVec.y += cVec[1];

    double xf = datVec.x;
    double yf = datVec.y;

    // // If x-axis is log scale
    // if (isLogScaleX) {
    //   xf = isLogScaleXNegative ? -pow(10, xf) : pow(10, xf);
    // }
    //
    // // If y-axis is log scale
    // if (isLogScaleY) {
    //   yf = isLogScaleYNegative ? -pow(10, yf) : pow(10, yf);
    // }

    return [xf, -yf];
  }

  List<String> getAxesLabels() {
    return labels;
  }
}

class DataSeries {
  final List<List<double>> dataPoints;

  DataSeries({required this.dataPoints});

  List<double> getPixel(int index) {
    return dataPoints[index];
  }

  int getCount() {
    return dataPoints.length;
  }
}


class AutoDetectionData {
  final List<int> bgColor;
  Set<int> binaryData = {};
  int imageWidth = 0;
  int imageHeight = 0;
  double colorDistance = 0;
  List<int>? fgColor;


  AutoDetectionData({this.bgColor = const [255, 255, 255]});
  // AutoDetectionData({this.fgColor = const [128, 128, 0], this.bgColor = const [255, 255, 255]});

  Future<void> generateBinaryData( imagePath, fgColor) async {
    final image = img.decodeImage(imagePath.readAsBytesSync());
    // final image = img.decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) return;

    imageWidth = image.width;
    imageHeight = image.height;
    final data = image.getBytes();

    for (int idx = 0; idx < data.length; idx += 4) {
      int r = data[idx];
      int g = data[idx + 1];
      int b = data[idx + 2];
      int a = data[idx + 3];

      if (a == 0) {
        r = g = b = 255;
      }

      double dist = sqrt(pow((r - fgColor[0]), 2) + pow((g - fgColor[1]), 2) + pow((b - fgColor[2]), 2));
      if (dist <= colorDistance) {
        binaryData.add(idx ~/ 4);
      }
    }
  }

  List<List<double>> getGeneralAxesData(DataSeries dataSeries, Axes axes, vmath.Matrix2 aMat, List<double> cVec, double xMin, double xMax, double yMin, double yMax,
      {bool isLogScaleX = false, bool isLogScaleXNegative = false,
        bool isLogScaleY = false, bool isLogScaleYNegative = false}) {
    List<List<double>> rawData = [];

    for (int i = 0; i < dataSeries.getCount(); i++) {
      var pt = dataSeries.getPixel(i);
      var ptData = axes.pixelToData(pt[0], pt[1], aMat, cVec,
          isLogScaleX: isLogScaleX, isLogScaleXNegative: isLogScaleXNegative,
          isLogScaleY: isLogScaleY, isLogScaleYNegative: isLogScaleYNegative);
      rawData.add(ptData);
        if (kDebugMode) {
          // print('${ptData[0]},${ptData[1]}');
        }
      // if (ptData[0] >= xMin && ptData[0] <= xMax && ptData[1] >= yMin && ptData[1] <= yMax) {
      //   rawData.add(ptData);
      // }
    }

    return rawData;
  }

  static Future<List<List<double>>> loadCsvData(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);

    List<List<double>> dataPoints = [];
    for (var row in rows) {
      dataPoints.add([row[0] as double, row[1] as double]);
    }
    return dataPoints;
  }

  static Future<void> saveCsvData(String filePath, List<List<double>> data) async {
    final file = File(filePath);
    final csvContent = const ListToCsvConverter().convert(data);
    await file.writeAsString(csvContent);
  }
}

class AveragingWindowCore {
  final Set<int> binaryData;
  final int imageWidth;
  final int imageHeight;
  final int xStep;
  final int yStep;
  // final int xMin;
  // final int xMax;
  // final int yMin;
  // final int yMax;
  List<List<double>> dataSeries = [];

  AveragingWindowCore({required this.binaryData, required this.imageWidth,
    required this.imageHeight, this.xStep = 1, this.yStep = 1});

  List<List<double>> run() {
    for (int col = 0; col < imageWidth; col++) {
      List<int> blobs = [];
      for (int row = 0; row < imageHeight; row++) {
        if (binaryData.contains(row * imageWidth + col)) {
          if (blobs.isEmpty || row > blobs.last + yStep) {
            blobs.add(row);
          } else {
            blobs[blobs.length - 1] = ((blobs.last + row) ~/ 2).toInt();
          }
        }
      }

      for (int y in blobs) {
        // dataSeries.add([col + 0.5, y + 0.5]);
        dataSeries.add([col + 0.5, imageHeight - (y + 0.5)]);
      }
      // for (int y in blobs) {
      //   double xValue = col + 0.5;
      //   double yValue = imageHeight - (y + 0.5);
      //   print("${xValue}, ${yValue}");
      //   // Check if the data point is within the specified x and y range
      //   if (xValue >= xMin && xValue <= xMax && yValue >= yMin && yValue <= yMax) {
      //     print("${xValue}, ${yValue}");
      //     dataSeries.add([xValue, yValue]);
      //   }
      // }
    }
    return dataSeries;
  }
}


Future image_converter(imageFile, hexColor, px, py, dp) async {
  final autoData = AutoDetectionData();
  Color intColor = Color(int.parse("0xff${hexColor.replaceFirst('#','')}"));
  await autoData.generateBinaryData(imageFile,[int.parse(intColor.red.toString()), int.parse(intColor.green.toString()), int.parse(intColor.blue.toString())]);
  // await autoData.generateBinaryData('assets/logo/page_0.png');

  final axes = Axes(
      // px: [388.572, 3179.19, 388.572, 388.572],
      // py: [1655.37, 1655.37, 1655.37, 235.19],
      px:px,
      py:py,
      dimensions: 2,
      dp: dp,
      // dp: ["0", "-30", "250", "-30", "0", "-30", "250", "30"],
      labels: ["X1", "X2", "Y1", "Y2"]
  );

  double x1 = px[0];
  double y1 = py[0];
  double x2 = px[1];
  double y2 = py[1];
  double x3 = px[2];
  double y3 = py[2];
  double x4 = px[3];
  double y4 = py[3];

  if (kDebugMode){
    print('x1: $x1');
    print('x2: $x2');
    print('x3: $x3');
    print('x4: $x4');
    print('y1: $y1');
    print('y2: $y2');
    print('y3: $y3');
    print('y4: $y4');
    print('dp : $dp');
  }
  // double x1 = 388.57202291110343;
  // double y1 = 1655.3711507293356;
  // double x2 = 3179.1896272285253;
  // double y2 = 1655.3711507293356;
  // double x3 = 388.57202291110343;
  // double y3 = 1655.3711507293356;
  // double x4 = 388.57202291110343;
  // double y4 = 235.1883296567205;

  // dp: ["0", "-30", "250", "-30", "0", "-30", "250", "30"],

  double xmin = double.parse(dp[0]);
  double xmax = double.parse(dp[2]);
  double ymin = double.parse(dp[1]);
  double ymax = double.parse(dp[7]);

  // double xmin = 0;
  // double xmax = 250;
  // double ymin = -30;
  // double ymax = 30;
  if( kDebugMode){
    print('xmin : $xmin');
    print('xmax : $xmax');
    print('ymin : $ymin');
    print('ymax : $ymax');
  }


  // Define the matrices and vectors
  final datMat = vmath.Matrix2(xmin - xmax, 0, 0, ymin - ymax);
  final pixMat = vmath.Matrix2(x1 - x2, 0, 0, y3 - y4);
  // final pixMat = vmath.Matrix2(x1 - x2, x3 - x4, y1 - y2, y3 - y4);
  if (kDebugMode) {
    print('datMat : $datMat');
    print('pixMat : $pixMat');
  }

  // Matrix multiplication and inversion
  final aMat = datMat.multiplied(pixMat.clone()..invert());
  if (kDebugMode) {
    print('aMat : $aMat');
  }

  // Calculation of cVec
  final cVec = [
    xmin - aMat.entry(0, 0) * x1 - aMat.entry(0, 1) * y1,
    ymin - aMat.entry(1, 0) * x3 - aMat.entry(1, 1) * y3
  ];

  if (kDebugMode) {
    print('cVec : $cVec');
  }

  final averagingAlgo = AveragingWindowCore(
      binaryData: autoData.binaryData,
      imageWidth: autoData.imageWidth,
      imageHeight: autoData.imageHeight,
      xStep: 1,
      yStep: 1
  );

  final dataSeries = averagingAlgo.run();

  final transformedData = autoData.getGeneralAxesData(DataSeries(dataPoints: dataSeries), axes, aMat, cVec, xmin, xmax, ymin, ymax);
  if (kDebugMode) {
    print(transformedData);
    print(transformedData.length);
  }

  // Output the transformed data to a new CSV file
  const outputFilePath = 'transformed_data.csv';
  // await AutoDetectionData.saveCsvData(outputFilePath, transformedData);

  if (kDebugMode) {
    print('Transformed data saved to $outputFilePath');
  }
  return transformedData;
}

