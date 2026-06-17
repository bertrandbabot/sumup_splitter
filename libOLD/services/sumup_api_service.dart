import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sumup_transaction.dart';

class SumupApiService {
  final String apiKey;
  final String merchantCode;

  const SumupApiService({
    required this.apiKey,
    required this.merchantCode,
  });

  Future<List<SumupTransaction>> getRecentTransactions({int limit = 10}) async {
    final uri = Uri.https(
      'api.sumup.com',
      '/v2.1/merchants/$merchantCode/transactions/history',
      {
        'limit': limit.toString(),
        'order': 'descending',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur SumUp ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawItems = decoded is Map<String, dynamic> ? decoded['items'] : null;

    if (rawItems is! List) {
      return [];
    }

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(SumupTransaction.fromJson)
        .toList();
  }
}
