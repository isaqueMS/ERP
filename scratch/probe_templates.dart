
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const token = 'EAAUP7nMpXDABRBAZBRTlLpmbTRJ5oPiOEwTHOy4F24RCkyWfOxuBO3K5KRins2QZB27Ixq1EAGOMtk7LoY7iAmKnNJYE4WIiLZCg3puRcGyl9ZC4cHJHZAUZCbZAwjfrDTXvwFJImuO1ZBq0iU1Y4Pbszv0oXlgWE5SqT8xZBZAkzCUVJFLE9NN9fVUwXdN8wZApwZDZD';
  
  print('--- Buscando Contas de WhatsApp do Usuário ---');
  final response = await http.get(
    Uri.parse('https://graph.facebook.com/v21.0/me?fields=id,name,whatsapp_business_accounts'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode != 200) {
    print('Erro: ${response.body}');
    return;
  }
  
  final data = jsonDecode(response.body);
  print('Usuário: ${data['name']}');
  
  final wabaData = data['whatsapp_business_accounts'];
  if (wabaData == null || (wabaData['data'] as List).isEmpty) {
    print('Nenhuma conta comercial encontrada diretamente no Token.');
  } else {
    final wabaId = wabaData['data'][0]['id'];
    print('WABA ID Principal: $wabaId');
    
    print('\n--- Abrindo lista de todos os templates ---');
    final tResponse = await http.get(
      Uri.parse('https://graph.facebook.com/v21.0/$wabaId/message_templates'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (tResponse.statusCode == 200) {
      final tData = jsonDecode(tResponse.body);
      final list = tData['data'] as List;
      for (var t in list) {
        print('Template Encontrado: ${t['name']} | Idioma: ${t['language']} | Status: ${t['status']}');
      }
    } else {
      print('Falha ao listar templates do WABA $wabaId');
    }
  }
}
