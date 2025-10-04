import 'package:flutter/material.dart';

class FontTestWidget extends StatelessWidget {
  const FontTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Font Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Montserrat Regular (weight 400)',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w400, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Montserrat Bold (weight 700)',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Montserrat Light (weight 300)',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w300, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Montserrat Black (weight 900)',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
