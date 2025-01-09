import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScatterGraphScreen extends StatefulWidget {
  const ScatterGraphScreen(this.data, {super.key});
  final List<List<double>> data;


  @override
  State<ScatterGraphScreen> createState() => _ScatterGraphScreenState();
}

class _ScatterGraphScreenState extends State<ScatterGraphScreen> {
  int touchedIndex = -1;
  List<List<double>>? plotData;
  List<int> selectedSpots = [];
  final double _radiusSize = 2.5;
  bool isDragging = false;
  int? draggingPointIndex;
  // double baseRadiusSize = 1.0;

  @override
  void initState() {
    super.initState();
    plotData = widget.data;
  }

  void _addPoint(double x, double y) {
    setState(() {
      plotData?.add([x, y]);
    });
  }


  Future<void> writeCSV(csv) async {
    String csvData = const ListToCsvConverter().convert(csv);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/Dataset.csv";
    final file = File(path);

    await file.writeAsString(csvData);
    if (kDebugMode) {
      print("CSV file saved at: $path");
    }
  }

  Future<void> shareCSV() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/Dataset.csv";
    XFile xFile = XFile(path);
    Share.shareXFiles([xFile], text: 'Here is your CSV file');
  }

  void _deleteSelectedPoints() {
    setState(() {
      selectedSpots.sort((a, b) => b.compareTo(a));
      for (int index in selectedSpots) {
        plotData?.removeAt(index);
      }
      selectedSpots.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
            margin: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 3,
              child: Stack(
                children: [
                  ScatterChart(
                    ScatterChartData(
                      scatterSpots: plotData!.asMap().entries.map((e) {
                        final index = e.key;
                        final double x = e.value[0];
                        final double y = e.value[1];
                        return ScatterSpot(
                          x,
                          y,
                          show:true,
                          dotPainter: FlDotCirclePainter(
                            color: selectedSpots.contains(index)
                                ?Colors.green
                                :Colors.red.shade400,
                            radius: _radiusSize,
                          )
                        );
                      }).toList(),
                      // minX: -5,
                      // maxX: 255,
                      // minY: -35,
                      // maxY: 35,
                      minX: (plotData!.map((data) => data[0]).reduce((a, b) => a < b ? a : b)) + (-5),
                      maxX: (plotData!.map((data) => data[0]).reduce((a, b) => a > b ? a : b)) + 5,
                      minY: (plotData!.map((data) => data[1]).reduce((a, b) => a < b ? a : b)) + (-5),
                      maxY: (plotData!.map((data) => data[1]).reduce((a, b) => a > b ? a : b)) + 5,
                      borderData: FlBorderData(
                        show: false,
                      ),
                      titlesData: const FlTitlesData(
                        show: false,
                      ),
                      showingTooltipIndicators: selectedSpots,
                      scatterTouchData: ScatterTouchData(
                        enabled: true,
                        handleBuiltInTouches: false,
                        mouseCursorResolver:
                            (FlTouchEvent touchEvent, ScatterTouchResponse? response) {
                          return response == null || response.touchedSpot == null
                              ? MouseCursor.defer
                              : SystemMouseCursors.click;
                        },
                        touchTooltipData: ScatterTouchTooltipData(
                          getTooltipColor: (ScatterSpot touchedBarSpot) {
                            return touchedBarSpot.dotPainter.mainColor;
                          },
                          getTooltipItems: (ScatterSpot touchedBarSpot) {
                            final bool isBgDark = _checkBgDark(touchedBarSpot);

                            final color1 = isBgDark ? Colors.grey[100] : Colors.black87;
                            final color2 = isBgDark ? Colors.white : Colors.black;
                            return ScatterTooltipItem(
                              'X: ',
                              textStyle: TextStyle(
                                height: 1.2,
                                color: color1,
                                fontStyle: FontStyle.italic,
                              ),
                              bottomMargin: 10,
                              children: [
                                TextSpan(
                                  text: '${touchedBarSpot.x.toInt()} \n',
                                  style: TextStyle(
                                    color: color2,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Y: ',
                                  style: TextStyle(
                                    height: 1.2,
                                    color: color1,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                TextSpan(
                                  text: touchedBarSpot.y.toInt().toString(),
                                  style: TextStyle(
                                    color: color2,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback:
                            (FlTouchEvent event, ScatterTouchResponse? touchResponse) {
                          if (touchResponse == null ||
                              touchResponse.touchedSpot == null) {
                            return;
                          }
                          if (event is FlTapUpEvent) {
                            print("FlTapUpEvent..............");
                            final sectionIndex = touchResponse.touchedSpot!.spotIndex;
                            setState(() {
                              if (selectedSpots.contains(sectionIndex)) {
                                selectedSpots.remove(sectionIndex);
                              } else {
                                if(!selectedSpots.contains(sectionIndex)){
                                  selectedSpots.add(sectionIndex);
                                  print(selectedSpots.length);
                                }
                              }
                            });
                          }
                          if (event is FlPanUpdateEvent){
                            final sectionIndex = touchResponse.touchedSpot!.spotIndex;
                            if(!selectedSpots.contains(sectionIndex)){
                              setState(() {
                                selectedSpots.add(sectionIndex);
                              });
                              print("FlPanUpdateEvent..............");

                            }

                          }

                        },
                      ),
                    ),

                  ),
                ],
              ),
            ),
          ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _addPoint(100, 0);
              if (kDebugMode) {
                print("data length..................................${plotData!.length}");
              }
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              _deleteSelectedPoints();
              if (kDebugMode) {
                print("data length..................................${plotData!.length}");
              }
            },
            child: const Icon(Icons.delete),
          ),
          const SizedBox(height: 10,),
          FloatingActionButton(
            onPressed: () async {
              await writeCSV(plotData);
              await shareCSV();
              if (kDebugMode) {
                print("data length..................................${plotData!.length}");
              }
            },
            child: const Icon(Icons.share),
          ),
        ],
      ),
    );
  }

  bool _checkBgDark(ScatterSpot touchedBarSpot) {
    // Replace the switch-like structure with simple if-else logic.
    if (touchedBarSpot.x == 4.0 && touchedBarSpot.y == 4.0) return false;
    if (touchedBarSpot.x == 2.0 && touchedBarSpot.y == 5.0) return false;
    if (touchedBarSpot.x == 4.0 && touchedBarSpot.y == 5.0) return true;
    if (touchedBarSpot.x == 8.0 && touchedBarSpot.y == 6.0) return true;
    if (touchedBarSpot.x == 5.0 && touchedBarSpot.y == 7.0) return true;
    if (touchedBarSpot.x == 7.0 && touchedBarSpot.y == 2.0) return true;
    if (touchedBarSpot.x == 3.0 && touchedBarSpot.y == 2.0) return true;
    if (touchedBarSpot.x == 2.0 && touchedBarSpot.y == 8.0) return false;
    if (touchedBarSpot.x == 8.0 && touchedBarSpot.y == 8.0) return true;
    if (touchedBarSpot.x == 5.0 && touchedBarSpot.y == 2.5) return false;
    if (touchedBarSpot.x == 3.0 && touchedBarSpot.y == 7.0) return true;
    return false;
  }
}
