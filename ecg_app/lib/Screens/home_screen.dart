import 'package:ecg_analyzer/Screens/data_receive_page.dart';
import 'package:ecg_analyzer/Screens/graph_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Services/BackgroundCollectingTask.dart';
import '../Services/prediction.dart';
import 'connected_devices_screen.dart';
import 'image_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  BackgroundCollectingTask? _collectingTask;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<String> signalFiles = ['0','1','2','3','4','5','6','7','8','9','10'];
  String? _selectedLocation;



  @override
  void initState() {
    super.initState();
    bluetoothStatusChecker();
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  Future<void> bluetoothStatusChecker() async {
    // Get initial state of Bluetooth
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  void showBluetoothSnackBar() {
    var snackBar = SnackBar(
      backgroundColor: Colors.blue,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Turn ON Bluetooth",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          SizedBox(width: 40,),
          IconButton(
            onPressed: () {
              FlutterBluetoothSerial.instance.requestEnable();
            },
            icon: Icon(Icons.toggle_off, color: Colors.white, size: 35),
          ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }



  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.white,
      body: Center(
      child: SizedBox(
        width:350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text("Select Signal Type",style: GoogleFonts.kanit(fontSize: 19),)),

              Image.asset("assets/logo/logo.png",height: 120,),

              GestureDetector(
                onTap: (){
                  if (kDebugMode) {
                    print('Image');
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageScreen()));
                },

                child: Container(
                  padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined),
                        const SizedBox(width: 10,),
                        Text("Add Image",style : GoogleFonts.kanit(fontSize: 16)),
                      ],
                    )),
              ),

              const SizedBox(height: 20,),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: DropdownButton<String>(
                    hint: Text('Select File',style: GoogleFonts.kanit(color: Colors.black),),
                    value: _selectedLocation,
                    onChanged: (String? newValue) async {
                      setState(() {
                        _selectedLocation = newValue;
                      });
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GraphScreen(_selectedLocation!)));
                    },
                    items: signalFiles.map((String signal) {
                      return DropdownMenuItem<String>(
                        value: signal,
                        child: Text('ECG signal ${signal}'),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20,),

              GestureDetector(
                onTap: () async {
                  if (_bluetoothState.isEnabled) {
                    print("Bluetooth is enabled");
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => SelectBondedDevicePage()));
                    final BluetoothDevice? selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return SelectBondedDevicePage(checkAvailability: false);
                        },
                      ),
                    );
                    if (selectedDevice != null) {
                      print('Connect -> selected ' + selectedDevice.address);
                      _startChat(context, selectedDevice);
                    } else {
                      print('Connect -> no device selected');
                    }
                  } else {
                    showBluetoothSnackBar();
                  }
                },

                child:
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monitor_heart_outlined),
                        const SizedBox(width: 10,),
                        Text("Live Signal",style : GoogleFonts.kanit(fontSize: 16)),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
              )
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

  Future<void> _startBackgroundTask(
      BuildContext context,
      BluetoothDevice server,
      ) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask!.start();
    } catch (ex) {
      _collectingTask?.cancel();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              new TextButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
