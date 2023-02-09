import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:google_fonts/google_fonts.dart';

int getAverage(List<int> list) {
  int average = 0;
  for (var n in list) {
    average += (n / list.length).floor();
  }

  return average;
}

int intListToInt(List<int> data) {
  if (data.isEmpty) return 0;
  Uint8List list = Uint8List.fromList(data);
  return list.buffer.asByteData().getUint16(0, Endian.little);
}

Future<dynamic> measuringSheet(
  context,
  BluetoothCharacteristic status,
  BluetoothCharacteristic freq,
) async {
  bool isMeasuring = false;
  bool hasResult = false;

  List<int> measuredDelay = [];
  StreamSubscription? setStateStream;

  await status.setNotifyValue(true);
  await freq.setNotifyValue(true);

  status.value.listen((value) {
    int data = intListToInt(value);
    if (data != 2 && isMeasuring) {
      isMeasuring = false;
      if (setStateStream != null) {
        setStateStream!.cancel();
      }
    }
  });
  freq.value.listen((_value) {
    int value = intListToInt(_value);
    if (value > 200 && value < 5000) {
      measuredDelay.add(value);
    }

    if (getAverage(measuredDelay) > 110 && isMeasuring) {
      hasResult = true;
    }
    // print("Freq: ${int.parse(utf8.decode(value).toString())}");
  });

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(12.0),
      ),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Frequenz messen",
                  style: GoogleFonts.robotoMono(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  "Die folgende Sequenz misst die Frequenz an der die Kugel am besten schwingt. Lenke dazu die Kugel so weit aus wie es geht und starte die Messung. Lasse die Kugel anschließend los. Die Messung läuft 5 Sekunden.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                hasResult && isMeasuring
                    ? Center(
                        child: Text(
                          "${((1.0 / getAverage(measuredDelay)) * 1000.0).toStringAsFixed(2)}Hz",
                          style: GoogleFonts.robotoMono(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Container(),
                const SizedBox(
                  height: 12,
                ),
                Center(
                  child: isMeasuring
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : hasResult
                          ? Text(
                              "Die gemessene Frequenz beträgt ${((1.0 / getAverage(measuredDelay)) * 1000.0).toStringAsFixed(2)}Hz",
                              style: GoogleFonts.robotoMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : CupertinoButton.filled(
                              onPressed: () {
                                setState(() {
                                  isMeasuring = true;
                                  hasResult = true;
                                });
                                setStateStream = Stream.periodic(
                                  const Duration(milliseconds: 200),
                                ).listen((event) {
                                  if (measuredDelay.length > 20) {
                                    setState(() {
                                      setStateStream!.cancel();
                                      isMeasuring = false;
                                    });
                                  } else {
                                    setStateStream!.cancel();
                                  }
                                });
                                // status.write(utf8.encode(2.toString()));
                              },
                              child: const Text(
                                "Messung starten",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                ),
                const Spacer(
                  flex: 2,
                )
              ],
            );
          },
        ),
      );
    },
  );
}
