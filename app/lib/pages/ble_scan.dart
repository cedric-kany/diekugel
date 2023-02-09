import 'package:die_kugel/components/ble-widgets.dart';
import 'package:die_kugel/components/info-card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:google_fonts/google_fonts.dart';

class BLEDeviceScanPage extends StatefulWidget {
  const BLEDeviceScanPage({super.key});

  @override
  State<BLEDeviceScanPage> createState() => _BLEDeviceScanPageState();
}

class _BLEDeviceScanPageState extends State<BLEDeviceScanPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 125, 171, 187),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 32,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
      ),
      body: DefaultTextStyle(
        style: GoogleFonts.robotoMono(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoCard(
              title: "Bluetooth",
              subtitle: "Suche nach der Kugel in der Nähe",
              children: [],
            ),
            const SizedBox(height: 32),
            StreamBuilder<BluetoothState>(
                stream: FlutterBlue.instance.state,
                initialData: BluetoothState.unknown,
                builder: (c, snapshot) {
                  final state = snapshot.data;
                  if (state == BluetoothState.on) {
                    return Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => FlutterBlue.instance.startScan(
                          timeout: const Duration(seconds: 4),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            StreamBuilder<List<BluetoothDevice>>(
                              stream: Stream.periodic(
                                const Duration(seconds: 2),
                              ).asyncMap(
                                (event) =>
                                    FlutterBlue.instance.connectedDevices,
                              ),
                              initialData: [],
                              builder: (context, snapshot) => Column(
                                children: snapshot.data!
                                    .map((device) => ListTile(
                                          title: Text(device.name),
                                          subtitle: Text(device.id.toString()),
                                          trailing: StreamBuilder<
                                              BluetoothDeviceState>(
                                            stream: device.state,
                                            initialData: BluetoothDeviceState
                                                .disconnected,
                                            builder: (context, snapshot) {
                                              if (snapshot.data ==
                                                  BluetoothDeviceState
                                                      .connected) {
                                                return TextButton(
                                                  onPressed: () {},
                                                  child: Text("OPEN"),
                                                );
                                              }
                                              return Text(
                                                snapshot.data.toString(),
                                              );
                                            },
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            StreamBuilder<List<ScanResult>>(
                              stream: FlutterBlue.instance.scanResults,
                              initialData: [],
                              builder: (context, snapshot) => Column(
                                children: snapshot.data!
                                    .map(
                                      (result) => ScanResultTile(
                                        result: result,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) {
                                            result.device.connect();
                                            return DeviceScreen(
                                              device: result.device,
                                            );
                                          }),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                          ]),
                        ),
                      ),
                    );
                  }
                  return const Center(
                    child: Text(
                      "Bluetooth ist ausgeschaltet!",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red[700],
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
              backgroundColor: Colors.blueGrey,
              onPressed: () => FlutterBlue.instance.startScan(
                timeout: const Duration(
                  seconds: 4,
                ),
              ),
              child: const Icon(Icons.search),
            );
          }
        },
      ),
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  List<int> _getRandomBytes() {
    return [0, 0, 0, 0];
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {
                      await c.write(_getRandomBytes(), withoutResponse: true);
                      await c.read();
                    },
                    onNotificationPressed: () async {
                      await c.setNotifyValue(!c.isNotifying);
                      await c.read();
                    },
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            onWritePressed: () => d.write(_getRandomBytes()),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return TextButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () => device.discoverServices(),
                      ),
                      IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => device.requestMtu(223),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
