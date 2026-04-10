import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsAppServiceResponse {
  final bool success;
  final String message;
  WhatsAppServiceResponse(this.success, this.message);
}

class WhatsAppService {
  static const String _accessToken = 'EAAUP7nMpXDABRBISuT4FvZAd50IUUd2Vy1att2AZB2afyd2XT2QQyyGskKQofI7ZC7dOY8y2LofL6BejOIZAij8TY5LdiirzDvFKOxVOSYboL6yZAkZC0QmNb57gm1cZALHo7J1Ubsw7wljjZAZCbuvbcC3kwEtiPBzAgWUx5ZBpiXrlBy5NkkWGZBPmKR0AC6xpsZCYSzOaI2QAqXVmL2GZC3a6JRkwYbwwrEHgU6MXQcxi8Dxd3rCM2IuCkWYyl7hbZAd16ZB7ICAQITA1uiLow3OGlwI';
  static const String _phoneNumberId = '1025304267340470';
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
        "name": templateName,
        "language": {"code": "pt_BR"},
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
        String errorMsg = 'Erro desconhecido';
        if (responseData['error'] != null) {
          int code = responseData['error']['code'];
          if (code == 131030) {
            errorMsg = 'Número não autorizado na lista de testes da Meta.';
          } else {
            errorMsg = responseData['error']['message'] ?? 'Erro na API';
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
