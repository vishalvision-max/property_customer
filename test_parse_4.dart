import 'dart:io';
import 'dart:convert';

void main() async {
  final uri = Uri.parse('https://propertysearch.visionvivante.in/api/v1/properties');
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    req.headers.set('Accept', 'application/json');

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('STATUS: \${res.statusCode}');
    print('BODY LENGTH: \${body.length}');
  } finally {
    client.close();
  }
}
