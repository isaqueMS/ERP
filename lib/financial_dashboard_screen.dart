import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'fluunt_drawer.dart';

class FinancialDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  final String userName;
  const FinancialDashboardScreen({super.key, this.onNavigation, this.userRole = 'agente', this.userName = '...'});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  DateTimeRange? _selectedDateRange;
  String? _selectedProfessionalId;
  String? _selectedClientId;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String? _agentStaffId;
  bool _isLoadingAgentId = false;

  @override
  void initState() {
    super.initState();
    // Default range: current month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    if (widget.userRole == 'agente') {
      _loadAgentStaffId();
    }
  }

  Future<void> _loadAgentStaffId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isLoadingAgentId = true);
    try {
      final email = (user.email ?? '').trim().toLowerCase();
      final snap = await FirebaseFirestore.instance
          .collection('staff')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snap.docs.isNotEmpty && mounted) {
        setState(() {
          _agentStaffId = snap.docs.first.id;
          _selectedProfessionalId = _agentStaffId; // Fixa o filtro
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar ID do agente: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAgentId = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFB6C1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: FluuntDrawer(
        selectedIndex: 7,
        onDestinationSelected: widget.onNavigation ?? (i) {},
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'DASHBOARD FINANCEIRO',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey),
            ),
            Text(
              widget.userName.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A3434)),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFFFB6C1)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDateRange == null 
                              ? 'Filtrar por data' 
                              : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.userRole == 'administrador') ...[
                _buildFilterIcon(Icons.person_outline, _selectedProfessionalId != null, _showProfessionalSelector),
                const SizedBox(width: 8),
              ],
              _buildFilterIcon(Icons.face_outlined, _selectedClientId != null, _showClientSelector),
              if (_hasFilters && widget.userRole == 'administrador') ...[
                const SizedBox(width: 8),
                _buildFilterIcon(Icons.close, false, _clearFilters, isAction: true),
              ]
            ],
          ),
        ],
      ),
    );
  }

  bool get _hasFilters => _selectedProfessionalId != null || _selectedClientId != null;

  void _clearFilters() {
    setState(() {
      _selectedProfessionalId = null;
      _selectedClientId = null;
    });
  }

  Widget _buildFilterIcon(IconData icon, bool isActive, VoidCallback onTap, {bool isAction = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFB6C1).withOpacity(0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(15),
          border: isActive ? Border.all(color: const Color(0xFFFFB6C1), width: 1.5) : null,
        ),
        child: Icon(icon, size: 20, color: isActive ? const Color(0xFFFFB6C1) : (isAction ? Colors.redAccent : Colors.grey)),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (widget.userRole == 'agente' && _isLoadingAgentId) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando seu perfil...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Erro ao carregar dados'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        
        // Manual filtering (since date is stored as string YYYY-MM-DD)
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = data['date'] as String;
          final date = DateTime.parse(dateStr);
          
          bool matchDate = true;
          if (_selectedDateRange != null) {
            matchDate = date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                        date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
          }

          bool matchProf = true;
          if (widget.userRole == 'agente') {
            // Se for agente, OBRIGATÓRIO bater com o ID do agente carragado
            matchProf = data['professionalId'] == _agentStaffId;
          } else {
            // Se for admin, segue o filtro selecionado (ou todos se null)
            matchProf = _selectedProfessionalId == null || data['professionalId'] == _selectedProfessionalId;
          }

          bool matchClient = _selectedClientId == null || data['clientId'] == _selectedClientId;

          return matchDate && matchProf && matchClient;
        }).toList();

        double totalIncome = 0;
        double totalExpense = 0;

        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] as num).toDouble();
          if (data['type'] == 'income') {
            totalIncome += amount;
          } else {
            totalExpense += amount;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSummary(totalIncome, totalExpense),
            if (widget.userRole.toLowerCase() == 'agente') ...[
              const SizedBox(height: 32),
              _buildAppointmentsSection(),
            ],
            const SizedBox(height: 32),
            const Text(
              'HISTÓRICO DE LANÇAMENTOS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            if (filteredDocs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('Nenhuma transação encontrada', style: TextStyle(color: Colors.grey))))
            else
              ...filteredDocs.map((doc) => _buildTransactionCard(doc.data() as Map<String, dynamic>)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildSummary(double income, double expense) {
    final balance = income - expense;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userRole.toLowerCase() == 'agente' ? 'MINHA PRODUÇÃO TOTAL' : 'SALDO NO PERÍODO', 
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
              ),
              const SizedBox(height: 8),
              Text(
                widget.userRole.toLowerCase() == 'agente' ? _currencyFormat.format(income) : _currencyFormat.format(balance),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              if (widget.userRole.toLowerCase() != 'agente') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    _summaryMiniCard('ENTRADAS', income, Colors.greenAccent),
                    const SizedBox(width: 16),
                    _summaryMiniCard('SAÍDAS', expense, Colors.redAccent),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryMiniCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_currencyFormat.format(value), style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final isIncome = data['type'] == 'income';
    final date = DateTime.parse(data['date']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              size: 20,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['category'] ?? 'Sem categoria',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(data['amount']),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM').format(date),
                style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfessionalSelector() async {
    final docs = await FirebaseFirestore.instance.collection('staff').get();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('FILTRAR POR PROFISSIONAL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: docs.docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
                itemBuilder: (context, index) {
                  final staff = docs.docs[index].data();
                  final id = docs.docs[index].id;
                  final isSelected = id == _selectedProfessionalId;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    title: Text(staff['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, color: isSelected ? const Color(0xFFFFB6C1) : Colors.black87)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFFFB6C1)) : null,
                    onTap: () {
                      setState(() => _selectedProfessionalId = id);
                      Navigator.pop(context);
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

  void _showClientSelector() async {
    final docs = await FirebaseFirestore.instance.collection('clients').orderBy('name').get();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('FILTRAR POR CLIENTE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: docs.docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
                itemBuilder: (context, index) {
                  final client = docs.docs[index].data();
                  final id = docs.docs[index].id;
                  final isSelected = id == _selectedClientId;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    title: Text(client['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, color: isSelected ? const Color(0xFFFFB6C1) : Colors.black87)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFFFB6C1)) : null,
                    onTap: () {
                      setState(() => _selectedClientId = id);
                      Navigator.pop(context);
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

  Widget _buildAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEUS AGENDAMENTOS NO PERÍODO',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateStr = data['date'] as String? ?? "";
              final date = DateTime.tryParse(dateStr);
              if (date == null || _selectedDateRange == null) return false;

              bool matchDate = date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));

              bool matchProf = true;
              if (widget.userRole.toLowerCase() == 'agente') {
                matchProf = (data['professionalId'] ?? data['staffId']) == _agentStaffId ||
                            data['creatorId'] == FirebaseAuth.instance.currentUser?.uid;
              }

              return matchDate && matchProf;
            }).toList();

            if (docs.isEmpty) return const Text('Nenhum agendamento encontrado.', style: TextStyle(color: Colors.grey, fontSize: 12));

            return SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = docs[index].data() as Map<String, dynamic>;
                  final price = (item['price'] is num) ? (item['price'] as num).toDouble() : (item['valor'] is num ? (item['valor'] as num).toDouble() : 0.0);
                  final dt = DateTime.tryParse(item['date'] ?? "");
                  
                  return Container(
                    width: 200, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(item['status']?.toUpperCase() ?? 'PENDENTE', style: const TextStyle(color: Color(0xFFFFB6C1), fontSize: 8, fontWeight: FontWeight.w900)),
                             Text(_currencyFormat.format(price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        Text(item['cliente'] ?? item['clientName'] ?? 'Cliente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(item['servico'] ?? item['service'] ?? 'Serviço', style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1),
                        const SizedBox(height: 8),
                        Text(dt != null ? DateFormat('dd/MM - HH:mm').format(dt) : '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
