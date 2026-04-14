
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const token = 'EAAUP7nMpXDABRBAZBRTlLpmbTRJ5oPiOEwTHOy4F24RCkyWfOxuBO3K5KRins2QZB27Ixq1EAGOMtk7LoY7iAmKnNJYE4WIiLZCg3puRcGyl9ZC4cHJHZAUZCbZAwjfrDTXvwFJImuO1ZBq0iU1Y4Pbszv0oXlgWE5SqT8xZBZAkzCUVJFLE9NN9fVUwXdN8wZApwZDZD';
  const phoneId = '1056793024186250';
  
  print('--- Verificando WABA ID ---');
  final wabaResponse = await http.get(
    Uri.parse('https://graph.facebook.com/v21.0/$phoneId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (wabaResponse.statusCode != 200) {
    print('Erro ao buscar WABA ID: ${wabaResponse.body}');
    return;
  }
  
  final wabaData = jsonDecode(wabaResponse.body);
  final wabaId = wabaData['whatsapp_business_account_id'];
  print('WABA ID: $wabaId');
  
  if (wabaId == null) {
     print('WABA ID não encontrado.');
     return;
  }

  print('\n--- Listando Templates ---');
  final templatesResponse = await http.get(
    Uri.parse('https://graph.facebook.com/v21.0/$wabaId/message_templates'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (templatesResponse.statusCode != 200) {
    print('Erro ao buscar templates: ${templatesResponse.body}');
    return;
  }
  
  final templatesData = jsonDecode(templatesResponse.body);
  final templates = templatesData['data'] as List;
  
  print('Encontrados ${templates.length} templates.\n');
  for (var t in templates) {
    print('Nome: ${t['name']}');
    print('Idioma: ${t['language']}');
    print('Status: ${t['status']}');
    print('---');
  }
}
