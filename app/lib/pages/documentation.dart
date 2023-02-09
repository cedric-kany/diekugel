import 'package:die_kugel/components/info-card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Konnte $url nicht öffnen!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const InfoCard(
          title: "Dokumentation",
          subtitle: "Team 4 - Mechatronik/Sensortechnik htw saar",
          children: [],
        ),
        const SizedBox(
          height: 20,
        ),
        Expanded(
          child: ListView(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.description,
                    color: Colors.grey[800],
                    size: 44,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onTap: () => _launchUrl(
                      "https://docs.google.com/document/d/e/2PACX-1vQpvLKZlSQOkisuM0zlXV5whEDKSONyZM-R8154HRvCO4Mg6tm5wVqBAmp9CJHU1AR1ruzVDsOJGZp3/pub"),
                  title: Text(
                    "Dokumentation",
                    style: GoogleFonts.robotoMono(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    "Dokumentation des Projekts",
                    style: GoogleFonts.robotoMono(
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(
                  thickness: 2,
                  indent: 12,
                  endIndent: 12,
                ),
                ListTile(
                  leading: SvgPicture.asset(
                    'assets/icons/github.svg',
                    color: Colors.grey[800],
                    height: 44,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onTap: () =>
                      _launchUrl("https://github.com/cedric-kany/diekugel"),
                  title: Text(
                    "GitHub",
                    style: GoogleFonts.robotoMono(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    "Projektdateien zum Nachbauen",
                    style: GoogleFonts.robotoMono(
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
        ),
      ],
    );
  }
}
