import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

import 'data_plot.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({super.key, required this.server});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPageState extends State<ChatPage> {
  static final clientID = 0;
  double rate = 0.0;
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;
  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';
  bool startFlag = false;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  List<double> data = [];
  List<double> displayData = [];
  int maxVisibleXRange = 200;
  int dataPointCounter = 0;
  int _currentMinX = 0;
  int _currentMaxX = 200;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      if (kDebugMode) {
        print('Connected to the device');
      }
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          if (kDebugMode) {
            print('Disconnecting locally!');
          }
        } else {
          if (kDebugMode) {
            print('Disconnected remotely!');
          }
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      if (kDebugMode) {
        print('Cannot connect, exception occurred');
        print(error);
      }
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Center(child: Text('Receiving ECG Data'))),
      body: Stack(
        children: [
          Column(
            children: [
              Divider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        int dragDirection = details.delta.dx < 0 ? 1 : -1;
                        _currentMinX += dragDirection * 1; // Adjust the factor for sensitivity
                        _currentMaxX += dragDirection * 1;

                        // Clamp the values to the range of the data length
                        _currentMinX = _currentMinX.clamp(0, data.length - maxVisibleXRange);
                        _currentMaxX = _currentMaxX.clamp(maxVisibleXRange, data.length);
                      });
                    },
                    onTapUp: (details) {
                      setState(() {
                        double x = details.localPosition.dx;
                        selectedIndex = ((x / MediaQuery.of(context).size.width) * maxVisibleXRange + _currentMinX).toInt();
                      });
                    },
                    child: LineChart(

                      LineChartData(
                        maxX: _currentMaxX.toDouble(),
                        minX: _currentMinX.toDouble(),
                        minY: -0.2,
                        maxY: 1.2,
                        lineTouchData: LineTouchData( enabled: false,),
                        lineBarsData: [
                          LineChartBarData(
                            color: Colors.red,
                            spots: _createSpots(),
                            isCurved: false,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  startFlag
                      ? IconButton(
                    icon: Icon(Icons.pause, color: isConnected ? Colors.red : Colors.grey),
                    onPressed: () {
                      _sendMessage("0");
                      setState(() {
                        startFlag = false;
                      });
                    },
                  )
                      : IconButton(
                    icon: Icon(Icons.play_arrow, color: isConnected ? Colors.green : Colors.grey),
                    onPressed: isConnected ? () {
                      _sendMessage("1");
                      setState(() {
                        startFlag = true;
                      });
                    }: null,
                  ),
                  Visibility(
                    visible: data.length > 1000 && !startFlag,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedIndex != -1) {
                          List<double> predictionData = _processSelectedData(selectedIndex);
                          print(predictionData);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DataPlot(predictionData)));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please select a point on the chart"),
                            backgroundColor: Colors.blue,),
                          );
                        }
                      },
                      child: Text("Extract"),
                    ),
                  ),
                  Text("${data.length.toString()} Dp"),
                ],
              ),
              SizedBox(height: 5,),
            ],
          ),
        ],
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    String dataString = String.fromCharCodes(data);
    int index = dataString.indexOf("\r\n");
    if (index != -1) {
      String messageText = _messageBuffer + dataString.substring(0, index);
      _messageBuffer = dataString.substring(index + 2);
      _addDataPoint(messageText);
    } else {
      _messageBuffer += dataString;
    }
  }

  void _addDataPoint(String message) {
    try {
      double yValue = double.parse(message.trim());
      setState(() {
        data.add(yValue / 4000);
        dataPointCounter++;

        if (data.length > maxVisibleXRange) {
          if (startFlag) {
            _currentMinX = data.length - maxVisibleXRange;
            _currentMaxX = data.length;
          }
        }

        if (dataPointCounter >= 5) {
          dataPointCounter = 0;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error converting message to double: $e');
      }
    }
  }

  List<FlSpot> _createSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }
    return spots;
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.isNotEmpty) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(const Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
            listScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 333),
            curve: Curves.easeOut,
          );
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  List<double> _processSelectedData(int index) {
    List<double> selectedData;
    if (index + 1000 <= data.length) {
      selectedData = data.sublist(index, index + 1000);
    } else {
      selectedData = data.sublist(data.length - 1000);
    }
    return selectedData;
  }


}
