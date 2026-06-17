import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sumup_receipt.dart';
import '../models/sumup_transaction.dart';

class SumupApiService {
  final String apiKey;
  final String merchantCode;

  const SumupApiService({
    required this.apiKey,
    required this.merchantCode,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      };

  Future<List<SumupTransaction>> getRecentTransactions({int limit = 10}) async {
    final uri = Uri.https(
      'api.sumup.com',
      '/v2.1/merchants/$merchantCode/transactions/history',
      {
        'limit': limit.toString(),
        'order': 'descending',
      },
    );

    print('[SUMUP] GET transactions/history: $uri');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    print('[SUMUP] transactions/history status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('[SUMUP] transactions/history body: ${response.body}');
      throw Exception(
          'Erreur SumUp transactions ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawItems = decoded is Map<String, dynamic> ? decoded['items'] : null;

    if (rawItems is! List) {
      print('[SUMUP] transactions/history: aucun item');
      return [];
    }

    print(
        '[SUMUP] transactions/history: ${rawItems.length} transaction(s) reçue(s)');

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(SumupTransaction.fromJson)
        .toList();
  }

  Future<SumupReceipt> getReceiptByTransactionCode(
      String transactionCode) async {
    final code = transactionCode.trim();
    if (code.isEmpty) {
      throw Exception('transaction_code vide');
    }

    final uri = Uri.https(
      'api.sumup.com',
      '/v1.1/receipts/$code',
      {'mid': merchantCode},
    );

    print('[SUMUP] GET receipt: $uri');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    print('[SUMUP] receipt $code status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('[SUMUP] receipt $code body: ${response.body}');
      throw Exception(
          'Erreur SumUp receipt ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Réponse receipt invalide pour $code');
    }

    final receipt = SumupReceipt.fromJson(decoded);
    print('[SUMUP] receipt $code: ${receipt.products.length} produit(s)');
    for (final product in receipt.products) {
      print('[SUMUP] produit: ${product.quantity} x ${product.name}');
    }
    return receipt;
  }
}
