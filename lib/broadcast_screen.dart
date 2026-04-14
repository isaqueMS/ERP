import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'whatsapp_service.dart';
import 'fluunt_drawer.dart';
import 'core/secrets.dart';

class BroadcastScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  const BroadcastScreen({super.key, this.onNavigation, this.userRole = 'agente'});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final TextEditingController _messageController = TextEditingController(
    text: 'Olá, [NOME]! 🌸 Temos uma novidade especial para você aqui no Estúdio Alê...'
  );
  final TextEditingController _templateController = TextEditingController(text: 'hello_world'); 
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _selectedClients = [];
  final List<Map<String, dynamic>> _clientsData = []; 

  bool _isSending = false;
  bool _useTemplate = false;
  String _lastLogs = '';
  String _searchQuery = '';

  static const _textPrimary = Color(0xFF4A3434);
  static const _roseGold = Color(0xFFE5B5B5);
  static const _quartz = Color(0xFFFCE7E7);
  static const _bg = Color(0xFFFFFFFF);

  void _insertTag(String tag) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(selection.start, selection.end, tag);
    _messageController.text = newText;
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> docs) {
    setState(() {
      if (_selectedClients.length == docs.length) {
        _selectedClients.clear();
      } else {
        _selectedClients.clear();
        for (var doc in docs) {
          final phone = doc['phone'] ?? '';
          if (phone.isNotEmpty) _selectedClients.add(phone);
        }
      }
    });
  }

  Future<void> _sendBulkMessages({bool useTemplate = true}) async {
    if (_selectedClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um cliente.'), backgroundColor: _textPrimary),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _lastLogs = '🚀 Iniciando transmissão (${useTemplate ? "Modelo" : "Livre"})...\n';
    });
    
    int successCount = 0;

    for (var phone in _selectedClients) {
      final client = _clientsData.firstWhere((c) => c['phone'] == phone, orElse: () => {'name': 'Cliente'});
      setState(() => _lastLogs += 'Enviando para ${client['name']}...\n');
      
      WhatsAppServiceResponse result;
      
      if (useTemplate) {
        result = await WhatsAppService.sendTemplateMessage(
          to: phone,
          templateName: 'studio',
        );
      } else {
        result = await WhatsAppService.sendTextMessage(
          to: phone,
          message: _messageController.text.replaceAll('[NOME]', client['name']),
        );
      }
      
      setState(() {
        _lastLogs += result.success ? "   ✅ Sucesso!\n" : "   ❌ Falha: ${result.message}\n";
      });

      if (result.success) successCount++;
    }

    setState(() => _isSending = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transmissão finalizada: $successCount enviado(s).'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: FluuntDrawer(selectedIndex: 9, onDestinationSelected: widget.onNavigation ?? (i) {}, userRole: widget.userRole),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            backgroundColor: _bg,
            elevation: 0,
            iconTheme: const IconThemeData(color: _textPrimary),
            title: Column(
              children: [
                const Text('Compor Mensagem', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
                Text('ID ATIVO: ...${AppSecrets.whatsappPhoneId.substring(AppSecrets.whatsappPhoneId.length - 4)}', 
                     style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildComposerCard(),
                   const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Filtro e Selecionar Todos
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clients').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox());
              final docs = snapshot.data!.docs;
              final filtered = docs.where((doc) => doc['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: filtered.isNotEmpty && _selectedClients.length == filtered.length,
                                  activeColor: _roseGold,
                                  onChanged: (v) => _toggleSelectAll(filtered),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const Text('Selecionar Todos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _textPrimary)),
                            ],
                          ),
                          Text('${_selectedClients.length} selecionados', style: const TextStyle(fontWeight: FontWeight.w900, color: _roseGold, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            }
          ),

          _buildClientList(),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildActionButtons(),
    );
  }

  Widget _buildComposerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: _textPrimary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: _quartz),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 10, 5),
            child: Row(
              children: [
                const Icon(Icons.mode_edit_outline_outlined, color: _roseGold, size: 20),
                const SizedBox(width: 10),
                const Text('MENSAGEM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: _textPrimary, letterSpacing: 1)),
                const Spacer(),
                Switch(
                  value: _useTemplate, 
                  activeColor: _roseGold,
                  onChanged: (v) => setState(() => _useTemplate = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _quartz.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.5),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Escreva sua mensagem aqui ou use para preencher o modelo...'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Wrap(
              spacing: 8,
              children: [
                _tagChip('[NOME]', () => _insertTag('[NOME]')),
                _tagChip('[DATA]', () => _insertTag('[DATA]')),
                _tagChip('📍 Estúdio Alê', () => _insertTag('Estúdio Alê')),
              ],
            ),
          ),
          // Botoes de Ação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : () => _sendBulkMessages(useTemplate: true),
                    icon: const Icon(Icons.rocket_launch, size: 16),
                    label: const Text('Modelo Studio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roseGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : () => _sendBulkMessages(useTemplate: false),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Texto Livre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_lastLogs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_lastLogs, style: const TextStyle(color: _roseGold, fontSize: 10, fontFamily: 'monospace')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _textPrimary)),
      backgroundColor: _quartz,
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Pesquisar cliente...',
        prefixIcon: const Icon(Icons.search_rounded, color: _roseGold),
        filled: true,
        fillColor: _quartz.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildClientList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clients').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        
        final docs = snapshot.data!.docs;
        _clientsData.clear();
        for (var d in docs) {
          _clientsData.add({'name': d['name'], 'phone': d['phone']});
        }

        final filtered = docs.where((doc) => doc['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final name = filtered[i]['name'];
              final phone = filtered[i]['phone'];
              final isSelected = _selectedClients.contains(phone);

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: CheckboxListTile(
                  value: isSelected,
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
                  subtitle: Text(phone, style: const TextStyle(fontSize: 12)),
                  secondary: CircleAvatar(backgroundColor: _quartz, child: Text(name[0], style: const TextStyle(color: _textPrimary))),
                  activeColor: _roseGold,
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  onChanged: (v) {
                    setState(() {
                      if (v!) _selectedClients.add(phone);
                      else _selectedClients.remove(phone);
                    });
                  },
                ),
              );
            },
            childCount: filtered.length,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 65,
        child: ElevatedButton(
          onPressed: _isSending ? null : _sendBulkMessages,
          style: ElevatedButton.styleFrom(
            backgroundColor: _textPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 10,
            shadowColor: _textPrimary.withOpacity(0.5),
          ),
          child: _isSending 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('DISPARAR MENSAGENS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }
}
