
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const token = 'EAAUP7nMpXDABRBAZBRTlLpmbTRJ5oPiOEwTHOy4F24RCkyWfOxuBO3K5KRins2QZB27Ixq1EAGOMtk7LoY7iAmKnNJYE4WIiLZCg3puRcGyl9ZC4cHJHZAUZCbZAwjfrDTXvwFJImuO1ZBq0iU1Y4Pbszv0oXlgWE5SqT8xZBZAkzCUVJFLE9NN9fVUwXdN8wZApwZDZD';
  const phoneId = '1056793024186250';
  const target = '5571991217251';
  
  print('--- Enviando Mensagem de Texto via API ---');
  
  final body = {
    "messaging_product": "whatsapp",
    "recipient_type": "individual",
    "to": target,
    "type": "text",
    "text": {
      "preview_url": false,
      "body": "Teste de Mensagem Direta via API (Sem Template) - Agencia Fluunt"
    }
  };
  
  final response = await http.post(
    Uri.parse('https://graph.facebook.com/v21.0/$phoneId/messages'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );
  
  print('Status: ${response.statusCode}');
  print('Resposta: ${response.body}');
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    print('\n✅ Mensagem enviada com sucesso!');
  } else {
    print('\n❌ Falha no envio.');
  }
}
