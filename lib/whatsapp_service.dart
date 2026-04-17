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
    String? headerImageUrl,
  }) async {
    // Garante que o número comece com 55 (Brasil) se não houver DDI
    String cleanNumber = to.replaceAll(RegExp(r'\D'), '');
    if (!cleanNumber.startsWith('55')) {
      cleanNumber = '55$cleanNumber';
    }

    // Se for Brasil e tiver 13 dígitos (55 + DDD + 9 + 8 números), 
    // removemos o 9 extra para compatibilidade com a API da Meta
    if (cleanNumber.startsWith('55') && cleanNumber.length == 13) {
      cleanNumber = '55' + cleanNumber.substring(4); // Pula 55 e o primeiro 9 (que é o 3º e 4º dígito se contar DDD)
      // Ajuste: 55 (0,1) + DDD (2,3) + 9 (4) -> queremos 55 + DDD + 8 restantes
      cleanNumber = cleanNumber.substring(0, 4) + cleanNumber.substring(5);
    }

    final Map<String, dynamic> body = {
      "messaging_product": "whatsapp",
      "to": cleanNumber,
      "type": "template",
      "template": {
        "name": templateName,
        "language": {"code": "en"},
        if (headerImageUrl != null || bodyParameters.isNotEmpty)
          "components": [
            if (headerImageUrl != null)
              {
                "type": "header",
                "parameters": [
                  {
                    "type": "image",
                    "image": {"link": headerImageUrl}
                  }
                ]
              },
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
        final wamid = responseData['messages']?[0]?['id'] ?? 'OK';
        return WhatsAppServiceResponse(true, 'Enviado! ID: $wamid');
      } else {
        String errorMsg = 'Erro ${response.statusCode}';
        if (responseData['error'] != null) {
          int code = responseData['error']['code'] ?? 0;
          String apiMsg = responseData['error']['message'] ?? '';
          errorMsg = 'Erro Meta #$code: $apiMsg';
          
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
    if (!cleanNumber.startsWith('55')) {
      cleanNumber = '55$cleanNumber';
    }

    if (cleanNumber.startsWith('55') && cleanNumber.length == 13) {
      cleanNumber = cleanNumber.substring(0, 4) + cleanNumber.substring(5);
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

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final wamid = responseData['messages']?[0]?['id'] ?? 'OK';
        return WhatsAppServiceResponse(true, 'Enviado! ID: $wamid');
      } else {
        final errorObj = responseData['error'] ?? {};
        final apiMsg = errorObj['message'] ?? 'Erro desconhecido';
        final code = errorObj['code'] ?? '0';
        return WhatsAppServiceResponse(false, 'Meta #$code: $apiMsg');
      }
    } catch (e) {
      return WhatsAppServiceResponse(false, 'Falha na conexão: $e');
    }
  }
}
