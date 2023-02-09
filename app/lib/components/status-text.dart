import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  const StatusText({
    Key? key,
    required this.value,
    required this.trueText,
    required this.falseText,
  }) : super(key: key);

  final bool value;
  final String trueText;
  final String falseText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: value ? Colors.green : Colors.red, shape: BoxShape.circle),
        ),
        const SizedBox(
          width: 8,
        ),
        Text(
          value ? trueText : falseText,
        ),
      ],
    );
  }
}
