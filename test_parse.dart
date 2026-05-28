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
    
    final decoded = jsonDecode(body);
    List items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final outer = decoded['data'] ?? decoded['properties'] ?? decoded['result'];
      if (outer is List) {
        items = outer;
      } else if (outer is Map) {
        final inner = outer['data'];
        items = inner is List ? inner : const [];
      } else {
        items = const [];
      }
    } else {
      items = const [];
    }
    print('Found ' + items.length.toString() + ' items');
  } finally {
    client.close();
  }
}
