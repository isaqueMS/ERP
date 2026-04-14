import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core/secrets.dart';

class WhatsAppServiceResponse {
  final bool success;
  final String message;
  WhatsAppServiceResponse(this.success, this.message);
}

class WhatsAppService {
  static const String _accessToken = AppSecrets.whatsappToken;
  static const String _phoneNumberId = AppSecrets.whatsappPhoneId;
  static const String _apiUrl = 'https://graph.facebook.com/v21.0/$_phoneNumberId/messages';

  static Future<WhatsAppServiceResponse> sendTemplateMessage({
    required String to,
    required String templateName,
    List<String> bodyParameters = const [],
  }) async {
    String cleanNumber = to.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.length == 11 && !cleanNumber.startsWith('55')) {
      cleanNumber = '55$cleanNumber';
    }

    final Map<String, dynamic> body = {
      "messaging_product": "whatsapp",
      "to": cleanNumber,
      "type": "template",
      "template": {
        "name": "hello_world",
        "language": {"code": "en_US"},
        "components": [
          if (bodyParameters.isNotEmpty)
            {
              "type": "body",
              "parameters": bodyParameters.map((text) => {"type": "text", "text": text}).toList(),
            }
        ]
      }
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WhatsAppServiceResponse(true, 'Enviado');
      } else {
        String errorMsg = 'Erro ${response.statusCode}';
        if (responseData['error'] != null) {
          int code = responseData['error']['code'] ?? 0;
          String apiMsg = responseData['error']['message'] ?? '';
          errorMsg = 'Erro Meta #$code: $apiMsg';
          
          // Adiciona detalhes adicionais se existirem (ex: erro de parâmetro)
          if (responseData['error']['error_data'] != null && 
              responseData['error']['error_data']['details'] != null) {
            errorMsg += ' - Detalhe: ${responseData['error']['error_data']['details']}';
          }

          if (code == 131030) {
            errorMsg = 'Número não autorizado na lista de testes da Meta.';
          }
        }
        return WhatsAppServiceResponse(false, errorMsg);
      }
    } catch (e) {
      return WhatsAppServiceResponse(false, 'Falha na conexão: $e');
    }
  }

  /// Envia uma mensagem de texto livre (sem template)
  static Future<WhatsAppServiceResponse> sendTextMessage({
    required String to,
    required String message,
  }) async {
    String cleanNumber = to.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length == 11 && !cleanNumber.startsWith('55')) {
      cleanNumber = '55$cleanNumber';
    }

    final Map<String, dynamic> body = {
      "messaging_product": "whatsapp",
      "to": cleanNumber,
      "type": "text",
      "text": {"body": message},
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WhatsAppServiceResponse(true, 'Enviado');
      } else {
        final responseData = jsonDecode(response.body);
        final errorMsg = responseData['error']?['message'] ?? 'Erro na API';
        return WhatsAppServiceResponse(false, errorMsg);
      }
    } catch (e) {
      return WhatsAppServiceResponse(false, 'Falha na conexão: $e');
    }
  }
}
