import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'fluunt_drawer.dart';

class StaffReportScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  const StaffReportScreen({super.key, this.onNavigation, this.userRole = 'agente'});

  @override
  State<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends State<StaffReportScreen> {
  // Profissional selecionado
  Map<String, dynamic>? _selectedStaff;
  String? _selectedStaffDocId;

  // Período
  DateTimeRange _selectedDateRange = _defaultDateRange();

  // Estado de carregamento
  bool _isLoadingStaff = false;
  bool _isLoadingReport = false;

  // Dados do relatório
  int _totalServices = 0;
  double _grossRevenue = 0;
  double _netCommission = 0;

  // Lista de profissionais
  List<Map<String, dynamic>> _staffList = [];

  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateLabel = DateFormat('dd/MM/yyyy');

  static DateTimeRange _defaultDateRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoadingStaff = true);
    final snap = await FirebaseFirestore.instance.collection('staff').orderBy('name').get();
    final allStaff = snap.docs.map((d) => {'_docId': d.id, ...d.data()}).toList();
    
    if (mounted) {
      setState(() {
        _staffList = allStaff;
        _isLoadingStaff = false;
      });

      // Se for agente, auto-seleciona a si mesmo
      if (widget.userRole == 'agente') {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final email = (user.email ?? '').trim().toLowerCase();
          final me = _staffList.firstWhere(
            (s) => (s['email'] as String? ?? '').toLowerCase().trim() == email,
            orElse: () => {},
          );
          if (me.isNotEmpty) {
            setState(() {
              _selectedStaff = me;
              _selectedStaffDocId = me['_docId'];
            });
            _loadReport();
          }
        }
      }
    }
  }

  Future<void> _loadReport() async {
    if (_selectedStaffDocId == null) return;
    setState(() => _isLoadingReport = true);

    final startDate = _selectedDateRange.start;
    final endDate = _selectedDateRange.end;

    // Buscar transações (receitas) do profissional
    final txSnap = await FirebaseFirestore.instance
        .collection('transactions')
        .where('professionalId', isEqualTo: _selectedStaffDocId)
        .where('type', isEqualTo: 'income')
        .get();

    // Buscar agendamentos (concluídos) do profissional
    final appSnap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('professionalId', isEqualTo: _selectedStaffDocId)
        .get();

    double gross = 0;
    int count = 0;

    // Processar transações
    for (final doc in txSnap.docs) {
      final data = doc.data();
      final dateStr = (data['date'] ?? data['data']) as String? ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final date = DateTime.parse(dateStr);
        if (!date.isBefore(startDate) && !date.isAfter(endDate.add(const Duration(days: 1)))) {
          gross += (data['amount'] as num).toDouble();
          count++;
        }
      } catch (_) {}
    }

    // Processar agendamentos
    for (final doc in appSnap.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      
      // Ignora apenas os cancelados, para que 'Agendado' e 'Pendente' apareçam na produção.
      if (status == 'cancelado' || status == 'canceled' || status == 'cancelled') continue;
      
      final dateStr = (data['date'] ?? data['data']) as String? ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final date = DateTime.parse(dateStr);
        if (!date.isBefore(startDate) && !date.isAfter(endDate.add(const Duration(days: 1)))) {
          final price = (data['price'] is num) ? (data['price'] as num).toDouble() : (data['valor'] is num ? (data['valor'] as num).toDouble() : 0.0);
          gross += price;
          count++;
        }
      } catch (_) {}
    }

    // Comissão = faturamento bruto * percentual / 100
    final commissionPct = ((_selectedStaff?['commission'] as num?)?.toDouble() ?? 0);
    final net = gross * commissionPct / 100;

    setState(() {
      _totalServices = count;
      _grossRevenue = gross;
      _netCommission = net;
      _isLoadingReport = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFFB6C1),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      await _loadReport();
    }
  }

  void _showStaffPicker() {
    // Filtrar a lista se for agente
    final List<Map<String, dynamic>> displayList = widget.userRole == 'agente'
        ? _staffList.where((s) => (s['email'] as String? ?? '').toLowerCase().trim() == (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase().trim()).toList()
        : _staffList;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(
              widget.userRole == 'agente' ? 'CONFIRMAR MEU PERFIL' : 'SELECIONAR PROFISSIONAL',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: displayList.isEmpty
                  ? const Center(child: Text('Nenhum profissional encontrado.'))
                  : ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final staff = displayList[index];
                        final isSelected = _selectedStaffDocId == staff['_docId'];
                        final int commissionPct = (staff['commission'] as num?)?.toInt() ?? 0;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFB6C1).withOpacity(0.15),
                            child: Text(
                              (staff['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Color(0xFFFFB6C1), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            staff['name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFFFFB6C1) : const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text('${staff['specialty'] ?? ''} · Comissão $commissionPct%', style: const TextStyle(fontSize: 12)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFFFB6C1)) : null,
                          onTap: () {
                            setState(() {
                              _selectedStaff = staff;
                              _selectedStaffDocId = staff['_docId'];
                            });
                            Navigator.pop(ctx);
                            _loadReport();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedStaffDocId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: FluuntDrawer(
        selectedIndex: 8,
        onDestinationSelected: widget.onNavigation ?? (i) {},
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'RELATÓRIO DE PRODUÇÃO',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produção por\nProfissional',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.1),
            ),
            const SizedBox(height: 28),

            // ── Seletor de profissional ──────────────────────────────
            GestureDetector(
              onTap: _showStaffPicker,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: hasSelection
                      ? const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasSelection ? null : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: hasSelection
                          ? const Color(0xFF1E293B).withOpacity(0.25)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: hasSelection
                            ? Colors.white.withOpacity(0.12)
                            : const Color(0xFFFFB6C1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: hasSelection
                          ? Center(
                              child: Text(
                                (_selectedStaff!['name'] as String).substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            )
                          : const Icon(Icons.badge_outlined, color: Color(0xFFFFB6C1), size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSelection ? 'PROFISSIONAL' : 'SELECIONAR',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                              color: hasSelection ? Colors.white60 : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasSelection ? _selectedStaff!['name'] : 'Toque para escolher',
                            style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold,
                              color: hasSelection ? Colors.white : const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasSelection)
                            Text(
                              '${_selectedStaff!['specialty'] ?? ''} · ${(_selectedStaff!['commission'] as num?)?.toInt() ?? 0}% comissão',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                        ],
                      ),
                    ),
                    if (widget.userRole == 'administrador' || !hasSelection)
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: hasSelection ? Colors.white54 : Colors.grey,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Seletor de período ───────────────────────────────────
            GestureDetector(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB6C1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.date_range_outlined, color: Color(0xFFFFB6C1), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PERÍODO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(
                          '${_dateLabel.format(_selectedDateRange.start)} – ${_dateLabel.format(_selectedDateRange.end)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined, color: Color(0xFFFFB6C1), size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Indicadores ─────────────────────────────────────────
            if (!hasSelection)
              _buildEmptyState()
            else if (_isLoadingReport)
              const Center(child: Padding(padding: EdgeInsets.only(top: 60), child: CircularProgressIndicator()))
            else
              _buildIndicators(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6C1).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFFFFB6C1)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selecione um profissional\npara ver o relatório',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    final commissionPct = ((_selectedStaff?['commission'] as num?)?.toInt() ?? 0);
    // Produção total = gross revenue (mesma coisa, mas pode ser apresentada como "total atendimentos × valor médio")
    final avgTicket = _totalServices > 0 ? _grossRevenue / _totalServices : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de destaque: Comissão Líquida
        _buildHighlightCard(
          title: 'COMISSÃO LÍQUIDA',
          value: _currency.format(_netCommission),
          subtitle: '$commissionPct% sobre o faturamento bruto',
          icon: Icons.account_balance_wallet_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB6C1), Color(0xFFFF8FAB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        const SizedBox(height: 16),

        // Grid 2 colunas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'FATURAMENTO BRUTO',
                value: _currency.format(_grossRevenue),
                icon: Icons.trending_up_rounded,
                iconColor: Colors.green,
                bgColor: Colors.green.withOpacity(0.07),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                label: 'QTD. SERVIÇOS',
                value: '$_totalServices',
                icon: Icons.content_cut_rounded,
                iconColor: const Color(0xFF6366F1),
                bgColor: const Color(0xFF6366F1).withOpacity(0.07),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Ticket médio e total de produção
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'TICKET MÉDIO',
                value: _currency.format(avgTicket),
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFF59E0B).withOpacity(0.07),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildStatCard(
                label: 'TOTAL PRODUÇÃO',
                value: _currency.format(_grossRevenue),
                icon: Icons.auto_graph_rounded,
                iconColor: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFF0EA5E9).withOpacity(0.07),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6C1).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
