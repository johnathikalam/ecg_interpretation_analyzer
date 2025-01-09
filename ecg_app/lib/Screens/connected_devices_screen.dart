import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

class SelectBondedDevicePage extends StatefulWidget {
  final bool checkAvailability;

  const SelectBondedDevicePage({this.checkAvailability = true});

  @override
  _SelectBondedDevicePageState createState() => _SelectBondedDevicePageState();
}

enum DeviceAvailability { no, maybe, yes }

class DeviceWithAvailability {
  BluetoothDevice device;
  DeviceAvailability availability;
  int? rssi;

  DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _SelectBondedDevicePageState extends State<SelectBondedDevicePage> {
  List<DeviceWithAvailability> devices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;

  @override
  void initState() {
    super.initState();
    _fetchBondedDevices();
  }

  Future<void> _fetchBondedDevices() async {
    var bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {
      devices = bondedDevices
          .where((device) => device.name != null && device.name!.startsWith("ECG"))
          .map((device) => DeviceWithAvailability(
          device,
          widget.checkAvailability ? DeviceAvailability.maybe : DeviceAvailability.yes))
          .toList();
    });
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device', style: TextStyle(),),
        actions: [
          IconButton(
            onPressed: () => FlutterBluetoothSerial.instance.openSettings(),
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: devices.map((device) => BluetoothDeviceListEntry(
          device: device.device,
          rssi: device.rssi,
          enabled: device.availability == DeviceAvailability.yes,
          onTap: () => Navigator.of(context).pop(device.device),
        )).toList(),
      ),
    );
  }
}

class BluetoothDeviceListEntry extends StatelessWidget {
  final BluetoothDevice device;
  final int? rssi;
  final GestureTapCallback? onTap;
  final bool enabled;

  const BluetoothDeviceListEntry({
    required this.device,
    this.rssi,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(.15),
          borderRadius: BorderRadius.circular(25)
      ),
      child: ListTile(
        onTap: onTap,
        enabled: enabled,
        leading: const Icon(Icons.devices, color: Colors.black,),
        title: Text(device.name ?? "Unknown", style: TextStyle(color: Colors.black),),
        subtitle: Text(device.address.toString(), style: TextStyle(color: Colors.black54)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rssi != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(rssi.toString()),
                  const Text('dBm'),
                ],
              ),
            if (device.isConnected) const Icon(Icons.import_export, color: Colors.black54,),
            if (device.isBonded) const Icon(Icons.link, color: Colors.black87,),
          ],
        ),
      ),
    );
  }
}
