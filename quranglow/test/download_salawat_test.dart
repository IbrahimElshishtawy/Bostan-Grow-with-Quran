import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Download authentic Salawat MP3 via HttpClient', () async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('https://everyayah.com/data/Alafasy_128kbps/033056.mp3'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final file = File('android/app/src/main/res/raw/salawat.mp3');
        await file.parent.create(recursive: true);
        
        final bytes = <int>[];
        await for (var data in response) {
          bytes.addAll(data);
        }
        await file.writeAsBytes(bytes);
        debugPrint('Successfully written ${bytes.length} bytes to ${file.path}');
        expect(true, isTrue);
      } else {
        debugPrint('Error status: ${response.statusCode}');
        expect(false, isTrue);
      }
    } catch (e) {
      debugPrint('Caught: $e');
      expect(false, isTrue);
    } finally {
      client.close();
    }
  });
}
