import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

class SignalProcessor {

  predict(List<double> data) async {
    Interpreter interpreter = await Interpreter.fromAsset('assets/models/trial_2.tflite');
    // print("model loaded");
    if (data.length != 1000) {
      print('Error: Input data must have exactly 1000 elements.');
      return;
    }

    // Convert the input data to a Uint8List
    var inputArray = data.map((e) => e.toDouble()).toList();
    var reshapedInput = inputArray.reshape([1, 1000, 1]);    // var reshapedInput = Uint8List.fromList(inputArray); // Prepare the output buffer
    var output = List.filled(5, 0.0).reshape([1, 5]); // Run the model
    try {
      interpreter.run(reshapedInput, output);
      print('Output: $output');
    } catch (e) {
      print('Error running model: $e');
    }
  }


  // Generate Butterworth bandpass filter coefficients
  List<List<double>> butterBandpass(int order, double lowcut, double highcut, double fs) {
    double nyquist = 0.5 * fs;
    double low = lowcut / nyquist;
    double high = highcut / nyquist;

    // Pre-warp the frequencies
    double preW1 = tan(pi * low / 2);
    double preW2 = tan(pi * high / 2);

    // Calculate center frequency and bandwidth
    double w0 = sqrt(preW1 * preW2);
    double bw = preW2 - preW1;

    // Generate analog filter coefficients using bilinear transform
    List<double> a = List.filled(order + 1, 0.0);
    List<double> b = List.filled(order + 1, 0.0);

    // Calculate analog coefficients
    for (int i = 0; i <= order; i++) {
      a[i] = pow(-1, i).toDouble() * binomialCoeff(order, i).toDouble() * pow(w0, i).toDouble();
    }

    for (int i = 0; i <= order; i++) {
      b[i] = pow(w0, order - i).toDouble() * binomialCoeff(order, i).toDouble() * cos(pi * (2 * i + order - 1) / (2 * order)).toDouble();
    }

    // Normalize the coefficients
    double a0 = a.reduce((value, element) => value + element);
    for (int i = 0; i <= order; i++) {
      a[i] /= a0;
      b[i] /= a0;
    }

    return [b, a];
  }

  // Calculate binomial coefficient
  int binomialCoeff(int n, int k) {
    if (k > n - k) k = n - k;
    int c = 1;
    for (int i = 0; i < k; i++) {
      c = c * (n - i) ~/ (i + 1);
    }
    return c;
  }

  // Apply the Butterworth filter to the data
  List<double> bandpassFilter(List<double> data, int order, double lowcut, double highcut, double fs) {
    List<List<double>> coefficients = butterBandpass(order, lowcut, highcut, fs);
    List<double> b = coefficients[0];
    List<double> a = coefficients[1];

    List<double> y = List.filled(data.length, 0.0);

    for (int i = order; i < data.length; i++) {
      y[i] = b[0] * data[i];
      for (int j = 1; j <= order; j++) {
        y[i] += b[j] * data[i - j] - a[j] * y[i - j];
      }
    }

    return y;
  }

  // Normalize the data
  List<double> normalize(List<double> data) {
    // Filter out NaN values
    data = data.where((value) => value.isFinite).toList();

    if (data.isEmpty) {
      throw StateError('No valid elements to normalize');
    }

    double maxVal = data.reduce(max);
    double minVal = data.reduce(min);
    List<double> normalizedData = data.map((value) => (value - minVal) / (maxVal - minVal)).toList();
    return normalizedData;
  }


  List<int> detectRPeaks(List<double> data, double threshold) {
    List<int> rPeaks = [];
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > threshold && data[i] > data[i - 1] && data[i] > data[i + 1]) {
        rPeaks.add(i);
      }
    }
    return rPeaks;
  }

  // Calculate RR intervals from detected R-peaks
  List<double> calculateRRIntervals(List<int> rPeaks, double fs) {
    List<double> rrIntervals = [];
    for (int i = 1; i < rPeaks.length; i++) {
      double rrInterval = (rPeaks[i] - rPeaks[i - 1]) / fs;
      rrIntervals.add(rrInterval);
    }
    return rrIntervals;
  }

  // Calculate heart rate from RR intervals
  double calculateHeartRate(List<double> rrIntervals) {
    if (rrIntervals.isEmpty) return 0.0;
    double averageRRInterval = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    return 60.0 / averageRRInterval;
  }

  List<int> detectQRSOnsetOffset(List<double> data, int rPeakIndex) {
    int qrsOnset = rPeakIndex - 10;
    int qrsOffset = rPeakIndex + 10;
    return [qrsOnset, qrsOffset];
  }

  List<double> calculateQRSIntervals(List<int> rPeaks, List<double> data, double fs) {
    List<double> qrsDurations = [];
    for (int rPeak in rPeaks) {
      List<int> qrsBounds = detectQRSOnsetOffset(data, rPeak);
      double qrsDuration = (qrsBounds[1] - qrsBounds[0]) / fs;
      qrsDurations.add(qrsDuration);
    }
    return qrsDurations;
  }


  void processECGData(List<double> ecgData, double fs) {
    List<double> normalizedData = normalize(ecgData);
    List<int> rPeaks = detectRPeaks(normalizedData, 0.6);
    if (kDebugMode) {
      print(rPeaks.length);
    }
    List<double> rrIntervals = calculateRRIntervals(rPeaks, fs);
    double heartRate = calculateHeartRate(rrIntervals);
    List<double> qrsDurations = calculateQRSIntervals(rPeaks, normalizedData, fs);

    if (kDebugMode) {
      print('Heart Rate: $heartRate bpm');
      print('RR Intervals: $rrIntervals');
      print('QRS Durations: $qrsDurations');
    }
  }
}
