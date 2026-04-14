
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const token = 'EAAUP7nMpXDABRBAZBRTlLpmbTRJ5oPiOEwTHOy4F24RCkyWfOxuBO3K5KRins2QZB27Ixq1EAGOMtk7LoY7iAmKnNJYE4WIiLZCg3puRcGyl9ZC4cHJHZAUZCbZAwjfrDTXvwFJImuO1ZBq0iU1Y4Pbszv0oXlgWE5SqT8xZBZAkzCUVJFLE9NN9fVUwXdN8wZApwZDZD';
  const phoneId = '1056793024186250';
  const target = '5571991217251'; // Seu numero de teste
  
  final langs = ['en', 'en_US', 'en_GB', 'pt_BR', 'pt'];
  
  print('--- Testando disparo de Template "studio" ---');
  
  for (var lang in langs) {
    print('Tentando com idioma: $lang...');
    
    final body = {
      "messaging_product": "whatsapp",
      "to": target,
      "type": "template",
      "template": {
        "name": "studio",
        "language": {"code": lang}
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
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ SUCESSO com o código: $lang!');
      print('Resposta: ${response.body}');
      break;
    } else {
      final data = jsonDecode(response.body);
      final error = data['error'] != null ? data['error']['message'] : 'Erro desconhecido';
      final detail = data['error'] != null && data['error']['error_data'] != null ? data['error']['error_data']['details'] : '';
      print('❌ FALHOU: $error ($detail)');
    }
    print('---');
  }
}
