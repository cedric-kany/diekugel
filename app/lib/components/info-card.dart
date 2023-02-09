import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, this.children, this.title, this.subtitle});
  final List<Widget>? children;
  final String? title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 32.0),
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          color: Color.fromARGB(255, 125, 171, 187)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title!,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          ...children!
        ],
      ),
    );
  }
}
