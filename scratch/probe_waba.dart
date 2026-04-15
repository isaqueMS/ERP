
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const token = 'EAAUP7nMpXDABRBAZBRTlLpmbTRJ5oPiOEwTHOy4F24RCkyWfOxuBO3K5KRins2QZB27Ixq1EAGOMtk7LoY7iAmKnNJYE4WIiLZCg3puRcGyl9ZC4cHJHZAUZCbZAwjfrDTXvwFJImuO1ZBq0iU1Y4Pbszv0oXlgWE5SqT8xZBZAkzCUVJFLE9NN9fVUwXdN8wZApwZDZD';
  
  print('--- Verificação Profunda de Scopes e WABAs ---');
  
  // 1. Tenta pegar o ID da conta via 'me'
  final meResp = await http.get(
    Uri.parse('https://graph.facebook.com/v21.0/me?fields=id,name,whatsapp_business_accounts'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  print('Resposta do "me": ${meResp.body}');
  
  // 2. Tenta listar WABAs compartilhados pelo Telefone
  const phoneId = '1056793024186250';
  final phoneResp = await http.get(
    Uri.parse('https://graph.facebook.com/v21.0/$phoneId?fields=whatsapp_business_account_id'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  print('Resposta do "PhoneID": ${phoneResp.body}');
}
