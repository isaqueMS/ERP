
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const token = 'EAAUP7nMpXDABRBAZBRTlLpmbTRJ5oPiOEwTHOy4F24RCkyWfOxuBO3K5KRins2QZB27Ixq1EAGOMtk7LoY7iAmKnNJYE4WIiLZCg3puRcGyl9ZC4cHJHZAUZCbZAwjfrDTXvwFJImuO1ZBq0iU1Y4Pbszv0oXlgWE5SqT8xZBZAkzCUVJFLE9NN9fVUwXdN8wZApwZDZD';
  
  print('--- Iniciando Varredura de Contas Comerciais (WABAs) ---');
  
  // Tenta encontrar o WABA ID através de vários endpoints conhecidos
  final endpoints = [
    'https://graph.facebook.com/v21.0/me?fields=id,name,whatsapp_business_accounts',
    'https://graph.facebook.com/v21.0/me/accounts?fields=id,name,whatsapp_business_account_id',
    'https://graph.facebook.com/v21.0/1056793024186250?fields=whatsapp_business_account_id,id,name'
  ];

  for (var url in endpoints) {
    print('\nTestando endpoint: $url');
    try {
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
      print('Status: ${resp.statusCode}');
      print('Resposta: ${resp.body}');
    } catch (e) {
      print('Erro ao acessar endpoint: $e');
    }
  }
}
