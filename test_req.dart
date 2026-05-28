import 'dart:io';
import 'dart:convert';

void main() async {
  final uri = Uri.parse('https://propertysearch.visionvivante.in/api/v1/owner/flats/under/fiftylakh');
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    req.headers.set('Accept', 'application/json');
    req.headers.set('Authorization', 'Bearer 117|KSTcawQULB00neG2PEDjE55DFP094gvpaLtAZAAI39d489c8');

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } finally {
    client.close();
  }
}
