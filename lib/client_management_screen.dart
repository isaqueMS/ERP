import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'fluunt_drawer.dart';
import 'whatsapp_service.dart';

class ClientManagementScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  const ClientManagementScreen({super.key, this.onNavigation, this.userRole = 'agente'});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _roseGold = Color(0xFFE5B5B5);
  static const _quartz = Color(0xFFFCE7E7);
  static const _textPrimary = Color(0xFF4A3434);
  static const _bg = Color(0xFFFFFFFF);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFE5B5B5),
      const Color(0xFFB5C8E5),
      const Color(0xFFB5E5C8),
      const Color(0xFFE5D8B5),
      const Color(0xFFD8B5E5),
      const Color(0xFFE5B5D2),
    ];
    final index = name.codeUnits.fold(0, (sum, c) => sum + c) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: FluuntDrawer(selectedIndex: 11, onDestinationSelected: widget.onNavigation ?? (i) {}, userRole: widget.userRole),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: _bg,
            elevation: 0,
            iconTheme: const IconThemeData(color: _textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clientes', style: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('clients').snapshots(),
                      builder: (ctx, snap) {
                        final count = snap.data?.docs.length ?? 0;
                        return Text('$count clientes cadastrados', style: const TextStyle(color: Colors.grey, fontSize: 12));
                      },
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(color: _quartz.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Buscar cliente...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: _roseGold),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clients').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _roseGold)));
              }

              final allDocs = snapshot.data!.docs;
              final filtered = _searchQuery.isEmpty
                  ? allDocs
                  : allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final phone = (data['phone'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) || phone.contains(_searchQuery);
                    }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person_search_rounded, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nenhum cliente encontrado', style: TextStyle(color: Colors.grey)),
                    ]),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final doc = filtered[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return _ClientCard(
                        clientId: doc.id,
                        data: data,
                        initials: _getInitials(data['name'] ?? ''),
                        avatarColor: _getAvatarColor(data['name'] ?? ''),
                        onTap: () => _openClientProfile(context, doc.id, data),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openClientProfile(BuildContext context, String clientId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientProfileSheet(
        clientId: clientId,
        data: data,
        initials: _getInitials(data['name'] ?? ''),
        avatarColor: _getAvatarColor(data['name'] ?? ''),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD DO CLIENTE (GRADE)
// ─────────────────────────────────────────────
class _ClientCard extends StatelessWidget {
  final String clientId;
  final Map<String, dynamic> data;
  final String initials;
  final Color avatarColor;
  final VoidCallback onTap;

  const _ClientCard({
    required this.clientId,
    required this.data,
    required this.initials,
    required this.avatarColor,
    required this.onTap,
  });

  static const _textPrimary = Color(0xFF4A3434);
  static const _roseGold = Color(0xFFE5B5B5);

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Sem nome';
    final phone = data['phone'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF5E8E8), width: 1.5),
          boxShadow: [
            BoxShadow(color: _roseGold.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: avatarColor.withOpacity(0.3), shape: BoxShape.circle),
                child: Center(
                  child: Text(initials, style: TextStyle(color: avatarColor, fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (phone.isNotEmpty)
                Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              // Último serviço badge
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('clientId', isEqualTo: clientId)
                    .limit(1)
                    .get(),
                builder: (_, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(30)),
                      child: const Text('Sem visitas', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w600)),
                    );
                  }
                  final lastDoc = snap.data!.docs.first.data() as Map<String, dynamic>;
                  final date = DateTime.tryParse(lastDoc['date'] ?? '') ?? DateTime.now();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _roseGold.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
                    child: Text(
                      DateFormat('dd/MM/yy').format(date),
                      style: const TextStyle(color: Color(0xFF4A3434), fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PERFIL DO CLIENTE (BOTTOM SHEET)
// ─────────────────────────────────────────────
class _ClientProfileSheet extends StatefulWidget {
  final String clientId;
  final Map<String, dynamic> data;
  final String initials;
  final Color avatarColor;

  const _ClientProfileSheet({
    required this.clientId,
    required this.data,
    required this.initials,
    required this.avatarColor,
  });

  @override
  State<_ClientProfileSheet> createState() => _ClientProfileSheetState();
}

class _ClientProfileSheetState extends State<_ClientProfileSheet> {
  final _msgController = TextEditingController();
  bool _sending = false;

  // Dados carregados
  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _sales = [];
  bool _loadingHistory = true;

  static const _textPrimary = Color(0xFF4A3434);
  static const _roseGold = Color(0xFFE5B5B5);
  static const _quartz = Color(0xFFFCE7E7);

  String get _clientName => widget.data['name'] ?? '';
  String get _clientPhone => (widget.data['phone'] ?? '').replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      // Buscar appointments (serviços) pelo ID do cliente
      final appointSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('clientId', isEqualTo: widget.clientId)
          .get();

      // Buscar nome do profissional para cada staffId
      final staffCache = <String, String>{};

      final visitList = <Map<String, dynamic>>[];
      for (final doc in appointSnap.docs) {
        final d = doc.data();
        final staffId = d['staffId'] ?? '';
        String staffName = '';
        if (staffId.isNotEmpty) {
          if (staffCache.containsKey(staffId)) {
            staffName = staffCache[staffId]!;
          } else {
            try {
              final staffDoc = await FirebaseFirestore.instance.collection('staff').doc(staffId).get();
              staffName = staffDoc.data()?['name'] ?? '';
              staffCache[staffId] = staffName;
            } catch (_) {}
          }
        }
        visitList.add({
          'type': 'servico',
          'date': DateTime.tryParse(d['date'] ?? '') ?? DateTime(2020),
          'service': d['service'] ?? 'Serviço',
          'professional': staffName,
          'valor': (d['price'] as num?)?.toDouble() ?? 0,
          'status': d['status'] ?? '',
        });
      }

      // Buscar vendas de produtos
      final salesSnap = await FirebaseFirestore.instance
          .collection('sales')
          .where('clientName', isEqualTo: _clientName)
          .get();

      final salesList = salesSnap.docs.map((doc) {
        final d = doc.data();
        DateTime date;
        final rawDate = d['date'];
        if (rawDate is Timestamp) {
          date = rawDate.toDate();
        } else if (rawDate is String) {
          date = DateTime.tryParse(rawDate) ?? DateTime(2020);
        } else {
          date = DateTime(2020);
        }
        return {
          'type': 'produto',
          'date': date,
          'service': 'Venda: ${d['productName'] ?? 'Produto'}',
          'professional': '',
          'valor': (d['total'] as num?)?.toDouble() ?? 0,
          'status': 'Pago',
        };
      }).toList();

      // Ordenar tudo por data (mais recente primeiro)
      visitList.addAll(salesList);
      visitList.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _visits = visitList;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _sendWhatsApp({String? templateName, String? message}) async {
    if (_clientPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente sem número de telefone cadastrado.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _sending = true);
    try {
      WhatsAppServiceResponse result;
      if (templateName != null) {
        result = await WhatsAppService.sendTemplateMessage(
          to: _clientPhone, 
          templateName: templateName,
          headerImageUrl: 'https://img.freepik.com/vetores-premium/logotipo-do-estudio-de-beleza-flores-de-cerejeira_23-2148507567.jpg',
        );
      } else {
        result = await WhatsAppService.sendTextMessage(to: _clientPhone, message: message ?? '');
      }

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mensagem enviada com sucesso! ✅'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha: ${result.message}'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessageDialog({String? predefined, String? title}) {
    _msgController.text = predefined ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(title ?? 'Enviar via WhatsApp', style: const TextStyle(fontWeight: FontWeight.w900, color: _textPrimary, fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Para: $_clientName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _msgController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Escreva sua mensagem...',
                filled: true,
                fillColor: _quartz.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          // Botão 1: Template Oficial
          ElevatedButton.icon(
            onPressed: _sending ? null : () {
              Navigator.pop(context);
              _sendWhatsApp(templateName: 'studio');
            },
            icon: const Icon(Icons.rocket_launch, size: 16),
            label: const Text('Enviar Modelo Studio', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _roseGold, 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
          ),
          // Botão 2: Texto Livre
          ElevatedButton.icon(
            onPressed: _sending ? null : () {
              Navigator.pop(context);
              _sendWhatsApp(message: _msgController.text);
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Enviar Texto Livre', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.data['phone'] ?? 'Não informado';
    final email = widget.data['email'] ?? 'Não informado';
    final notes = widget.data['notes'] ?? '';
    final birthRaw = widget.data['birthDate'] ?? '';
    String birth = 'Não informado';
    if (birthRaw.isNotEmpty) {
      final d = DateTime.tryParse(birthRaw);
      if (d != null) birth = DateFormat('dd/MM/yyyy').format(d);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),

            // Cabeçalho do perfil
            Row(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: widget.avatarColor.withOpacity(0.25), shape: BoxShape.circle),
                  child: Center(child: Text(widget.initials, style: TextStyle(color: widget.avatarColor, fontSize: 26, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_clientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _textPrimary, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    if (_visits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${_visits.length} atendimento(s)', style: TextStyle(color: _roseGold, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botões de WhatsApp
            Row(
              children: [
                Expanded(
                  child: _WppButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Nota de Serviço',
                    color: const Color(0xFF25D366),
                    onTap: () => _showMessageDialog(
                      title: 'Nota de Serviço',
                      predefined: 'Olá $_clientName! 💅 Sua visita ao Estúdio Alê foi um prazer! Obrigada pela sua preferência. Qualquer dúvida, estou à disposição. Até a próxima! 🌸',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WppButton(
                    icon: Icons.edit_rounded,
                    label: 'Msg Personalizada',
                    color: _roseGold,
                    onTap: () => _showMessageDialog(title: 'Mensagem Personalizada'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Informações do cliente
            _SectionTitle(title: 'INFORMAÇÕES', icon: Icons.info_outline_rounded),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.phone_rounded, label: 'Telefone', value: phone),
            _InfoRow(icon: Icons.email_rounded, label: 'E-mail', value: email),
            _InfoRow(icon: Icons.cake_rounded, label: 'Nascimento', value: birth),
            if (notes.isNotEmpty) _InfoRow(icon: Icons.notes_rounded, label: 'Observações', value: notes),

            const SizedBox(height: 28),

            // Histórico de serviços
            _SectionTitle(title: 'HISTÓRICO DE VISITAS', icon: Icons.history_rounded),
            const SizedBox(height: 12),

            if (_loadingHistory)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _roseGold)))
            else if (_visits.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('Nenhuma visita registrada ainda.', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._visits.map((v) => _VisitCard(
                date: v['date'] as DateTime,
                service: v['service'] as String,
                professional: v['professional'] as String,
                valor: v['valor'] as double,
                status: v['status'] as String,
                isProduto: v['type'] == 'produto',
                onSendNote: () => _showMessageDialog(
                  title: 'Nota via WhatsApp',
                  predefined: 'Olá $_clientName! 💅 Segue a nota do seu atendimento em ${DateFormat('dd/MM/yyyy').format(v['date'] as DateTime)}:\n➡️ ${v['service']}\n💰 Valor: R\$ ${(v['valor'] as double).toStringAsFixed(2)}\n\nObrigada pela preferência! Estúdio Alê 🌸',
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────
class _WppButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _WppButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE5B5B5), size: 16),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4A3434), letterSpacing: 1)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE5B5B5)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A3434))),
          ]),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final DateTime date;
  final String service;
  final String professional;
  final double valor;
  final String status;
  final bool isProduto;
  final VoidCallback onSendNote;

  const _VisitCard({
    required this.date,
    required this.service,
    required this.professional,
    required this.valor,
    required this.status,
    this.isProduto = false,
    required this.onSendNote,
  });

  @override
  Widget build(BuildContext context) {
    const roseGold = Color(0xFFE5B5B5);
    const textPrimary = Color(0xFF4A3434);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5E8E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: roseGold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(DateFormat('dd').format(date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary, height: 1)),
                Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service, style: const TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 14)),
              const SizedBox(height: 3),
              if (professional.isNotEmpty)
                Text('c/ $professional', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 6),
              Row(children: [
                Text('R\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: roseGold.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textPrimary)),
                ),
              ]),
            ]),
          ),
          // Botão de enviar nota
          IconButton(
            onPressed: onSendNote,
            icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 20),
            tooltip: 'Enviar nota desse serviço',
          ),
        ],
      ),
    );
  }
}
