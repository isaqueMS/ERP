import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'fluunt_drawer.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  final String userName;
  const HomeScreen({super.key, this.onNavigation, this.userRole = 'agente', this.userName = '...'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  late AnimationController _cardsAnim;
  late Animation<double> _cardsFade;

  static const _quartz = Color(0xFFFCE7E7);
  static const _quartzLight = Color(0xFFFDF2F2);
  static const _roseGold = Color(0xFFE5B5B5);
  static const _textPrimary = Color(0xFF4A3434);
  static const _bg = Color(0xFFFFFFFF);

  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    _cardsAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _cardsFade = CurvedAnimation(parent: _cardsAnim, curve: Curves.easeOut);
    _cardsAnim.forward();
    
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    if (widget.userRole == 'agente') {
      _loadAgentStaffId();
    }
  }

  String? _agentStaffId;
  bool _isLoadingAgentId = false;

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
        });
      } else {
        debugPrint("AVISO: E-mail ${user.email} não localizado na coleção 'staff'. Filtros podem ocultar dados.");
      }
    } catch (e) {
      debugPrint("Erro ao carregar ID do agente na Home: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAgentId = false);
    }
  }

  @override
  void dispose() {
    _cardsAnim.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _roseGold, onPrimary: Colors.white, onSurface: _textPrimary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRange = DateTimeRange(
          start: picked.start,
          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
      });
    }
  }

  String _userName() {
    return widget.userName;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: _bg,
        drawer: FluuntDrawer(selectedIndex: 0, onDestinationSelected: widget.onNavigation ?? (i) {}, userRole: widget.userRole),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              backgroundColor: _bg,
              elevation: 0,
              leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu_rounded, color: _textPrimary), onPressed: () => Scaffold.of(ctx).openDrawer())),
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Bem-vinda de volta,', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(_userName(), style: const TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          ],
                        ),
                      ),
                      Container(
                        width: 50, height: 50, decoration: BoxDecoration(color: _quartz, borderRadius: BorderRadius.circular(15)),
                        child: Center(child: Text(_userName().isNotEmpty ? _userName()[0] : '?', style: const TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w900))),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _cardsFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 32),
                      _buildFinancialSummary(), // Nova seção que soma tudo
                      const SizedBox(height: 32),
                      _buildServicesShowcase(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final isAdmin = widget.userRole.toLowerCase() == 'administrador' || widget.userRole.toLowerCase() == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(color: _quartzLight, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickAction(Icons.calendar_today_rounded, 'Agendar', _roseGold, () => widget.onNavigation?.call(1)),
          if (isAdmin) _quickAction(Icons.people_rounded, 'Clientes', _roseGold, () => widget.onNavigation?.call(11)),
          _quickAction(Icons.shopping_basket_rounded, 'Vender', const Color(0xFFC8A2C8), () => widget.onNavigation?.call(10)),
          if (isAdmin) _quickAction(Icons.chat_bubble_rounded, 'WhatsApp', _roseGold, () => widget.onNavigation?.call(9)),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _textPrimary)),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final range = _selectedRange!;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('CONTABILIDADE', Icons.account_balance_rounded),
            TextButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range_rounded, size: 16, color: _roseGold),
              label: Text("${DateFormat('dd/MM').format(range.start)} - ${DateFormat('dd/MM').format(range.end)}", style: const TextStyle(fontSize: 11, color: _roseGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Vamos usar o StreamBuilder de Transactions para a contabilidade real
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
          builder: (context, snapshot) {
            if (widget.userRole == 'agente' && _isLoadingAgentId) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white24)));
            }

            double totalIncome = 0;
            double totalExpense = 0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                
                DateTime? date;
                final rawDate = data['date'];
                
                if (rawDate is Timestamp) {
                  date = rawDate.toDate();
                } else if (rawDate is String) {
                  date = DateTime.tryParse(rawDate);
                }
                
                  if (date != null && date.isAfter(range.start) && date.isBefore(range.end)) {
                    // Filtro de Segurança por Cargo
                    // Se for agente, mostramos os lançamentos vinculados a ele OU criados por ele.
                    final creatorId = data['creatorId'] ?? "";
                    final professionalId = data['professionalId'] ?? "";
                    final user = FirebaseAuth.instance.currentUser;

                    if (widget.userRole == 'agente') {
                      bool isMine = (professionalId == _agentStaffId || creatorId == user?.uid);
                      if (!isMine && _agentStaffId != null) {
                        continue;
                      }
                    }

                    final rawAmount = data['amount'];
                    final amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;
                    
                    if (data['type'] == 'income') {
                      totalIncome += amount;
                    } else if (widget.userRole == 'administrador') {
                      // Agente não soma despesas
                      totalExpense += amount;
                    }
                  }
              }
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _textPrimary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: _textPrimary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statBubble(_currency.format(totalIncome), widget.userRole == 'agente' ? 'Minha Produção' : 'Entradas', Colors.greenAccent),
                      if (widget.userRole == 'administrador') ...[
                        _statBubble(_currency.format(totalExpense), 'Saídas', Colors.redAccent),
                        _statBubble(_currency.format(totalIncome - totalExpense), 'Saldo', Colors.white),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  const Text('O saldo acima já inclui o faturamento de serviços e venda de produtos.', style: TextStyle(color: Colors.white24, fontSize: 9)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _statBubble(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildServicesShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('CATÁLOGO DE SERVIÇOS', Icons.spa_rounded),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: _roseGold)));
            final docs = snapshot.data!.docs;
            final Map<String, List<Map<String, dynamic>>> grouped = {};
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final cat = data['category'] as String? ?? 'Outros';
              grouped.putIfAbsent(cat, () => []).add(data);
            }
            return Column(
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: entry.value.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) => _serviceCard(entry.value[i]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _serviceCard(Map<String, dynamic> svc) {
    final price = (svc['price'] as num?)?.toDouble() ?? 0;
    return Container(
      width: 150, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _quartz)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(svc['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(_currency.format(price), style: const TextStyle(color: _roseGold, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _roseGold, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _textPrimary, letterSpacing: 1)),
      ],
    );
  }
}
