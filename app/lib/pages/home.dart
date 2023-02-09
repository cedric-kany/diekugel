import 'dart:async';
import 'dart:convert' show utf8;
import 'package:die_kugel/pages/measuring_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../components/info-card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? isConnected = false;
  bool? isRunning;
  bool writeComplete = true;

  double? frequency;
  int? rotAngle;
  BluetoothCharacteristic? frequencyBLE;
  BluetoothCharacteristic? rotAngleBLE;
  BluetoothCharacteristic? statusBLE;

  @override
  void initState() {
    rotAngle = 0;
    frequency = 1 / 0.7;
    isRunning = false;

    Stream.periodic(
      const Duration(seconds: 5),
    )
        .asyncMap(
      (event) => FlutterBlue.instance.connectedDevices,
    )
        .listen((devices) async {
      if (devices.isNotEmpty) {
        for (var device in devices) {
          List<BluetoothService> services = await device.discoverServices();
          services.forEach((service) async {
            // do something with service
            // if(service.uuid)
            if (service.uuid == Guid("033b3bbd-7750-4d23-8572-6d75e07895a7")) {
              var characteristics = service.characteristics;
              for (BluetoothCharacteristic c in characteristics) {
                if (c.uuid == Guid("7f005c00-c0d6-491c-a999-9186af064d67")) {
                  frequencyBLE = c;
                } else if (c.uuid ==
                    Guid("7f005c01-c0d6-491c-a999-9186af064d67")) {
                  rotAngleBLE = c;
                } else if (c.uuid ==
                    Guid("7f005c02-c0d6-491c-a999-9186af064d67")) {
                  statusBLE = c;
                }
              }
            }
          });
        }
      }
      if (mounted) {
        setState(() {
          isConnected = devices.isNotEmpty;
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // bool isMoving = true;
    // bool isCharging = false;
    // int batteryVoltage = 2024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InfoCard(
          title: "Die Kugel",
          subtitle: "Steuerung",
          children: [
            Text(
              isConnected!
                  ? "~\$ Kugel ist bereit"
                  : "~\$ Kugel nicht verbunden",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            shrinkWrap: true,
            children: [
              Text(
                "Frequenz - ${frequency!.toStringAsFixed(2)}Hz",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
              Slider(
                divisions: 200,
                max: 2,
                min: 0.01,
                value: frequency!,
                onChanged: (value) async {
                  if (frequencyBLE != null && writeComplete) {
                    writeComplete = false;
                    int delay = ((1 / value) * 1000).toInt();

                    await frequencyBLE!.write(utf8.encode(delay.toString()));
                    writeComplete = true;
                  }

                  setState(() {
                    frequency = value;
                  });
                },
              ),
              Text(
                "Drehung - ${rotAngle!.toStringAsFixed(2)}°",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
              Slider(
                divisions: 90,
                max: 90,
                min: 0,
                value: rotAngle!.toDouble(),
                onChanged: (value) async {
                  if (rotAngleBLE != null) {
                    await rotAngleBLE!
                        .write(utf8.encode(value.toInt().toString()));
                  }
                  setState(() {
                    rotAngle = value.toInt();
                  });
                },
              ),
              const SizedBox(
                height: 32,
              ),
              Column(
                children: [
                  CupertinoButton.filled(
                    onPressed: () async {
                      if (statusBLE != null) {
                        await statusBLE!.write(
                            utf8.encode((isRunning! ? 0 : 1).toString()));
                        int delay = ((1 / frequency!) * 1000).toInt();
                        await frequencyBLE!
                            .write(utf8.encode(delay.toString()));

                        setState(() {
                          isRunning = !isRunning!;
                        });
                      }
                    },
                    child: Center(
                      child: Text(
                        isRunning! ? "Stop" : "Start",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  CupertinoButton.filled(
                    onPressed: () {
                      if (statusBLE != null) {
                        measuringSheet(context, statusBLE!, frequencyBLE!);
                      }
                    },
                    child: const Center(
                      child: Text(
                        "Frequenz messen",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
