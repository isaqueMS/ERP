import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fluunt_drawer.dart';

class TransactionRegistrationScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  const TransactionRegistrationScreen({super.key, this.onNavigation, this.userRole = 'agente'});

  @override
  State<TransactionRegistrationScreen> createState() => _TransactionRegistrationScreenState();
}

class _TransactionRegistrationScreenState extends State<TransactionRegistrationScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _transactionType = 'income';
  String _selectedCategory = 'Serviço Estúdio';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _categories = [
    'Serviço Estúdio', 
    'Venda Produto', 
    'Aluguel / Fixas', 
    'Materiais', 
    'Outros'
  ];

  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedProfessionalId;
  String? _selectedProfessionalName;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildSelectField({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFFB6C1), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProfessionalSelector() async {
    final docs = await FirebaseFirestore.instance.collection('staff').get();
    if (!mounted) return;
    _showPremiumPicker('SELECIONAR PROFISSIONAL', docs.docs.map((d) => d.data()['name'] as String).toList(), _selectedProfessionalName ?? '', (val) {
      final doc = docs.docs.firstWhere((d) => d.data()['name'] == val);
      setState(() {
        _selectedProfessionalId = doc.id;
        _selectedProfessionalName = val;
      });
    });
  }

  void _showClientSelector() async {
    final docs = await FirebaseFirestore.instance.collection('clients').orderBy('name').get();
    if (!mounted) return;
    _showPremiumPicker('SELECIONAR CLIENTE', docs.docs.map((d) => d.data()['name'] as String).toList(), _selectedClientName ?? '', (val) {
      final doc = docs.docs.firstWhere((d) => d.data()['name'] == val);
      setState(() {
        _selectedClientId = doc.id;
        _selectedClientName = val;
      });
    });
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o valor.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('transactions').add({
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'type': _transactionType,
        'category': _selectedCategory,
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'description': _descriptionController.text.trim(),
        'professionalId': _selectedProfessionalId ?? "",
        'professionalName': _selectedProfessionalName ?? "",
        'clientId': _selectedClientId ?? "",
        'clientName': _selectedClientName ?? "",
        'appointmentId': "", 
        'creatorId': user?.uid ?? "",
        'creatorName': user?.email?.split('@')[0] ?? "Admin",
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento realizado com sucesso!')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro de Conexão'),
            content: Text('Não foi possível gravar no banco de dados. Verifique sua internet ou permissões.\n\nDetalhe: $e'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _transactionType = 'income';
      _selectedCategory = 'Serviço Estúdio';
      _selectedDate = DateTime.now();
      _selectedClientId = null;
      _selectedClientName = null;
      _selectedProfessionalId = null;
      _selectedProfessionalName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: FluuntDrawer(
        selectedIndex: 6,
        onDestinationSelected: widget.onNavigation ?? (i) {},
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CAIXA / FINANCEIRO',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novo Lançamento',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
            ),
            const SizedBox(height: 32),

            // Toggle Tipo de Lançamento
            _buildTypeToggle(),
            const SizedBox(height: 32),

            _buildField(
              label: 'VALOR (R\$)', 
              hint: '0.00', 
              controller: _amountController, 
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              isLarge: true,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildDropdown(label: 'CATEGORIA', value: _selectedCategory, items: _categories, onChanged: (v) => setState(() => _selectedCategory = v!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePickerField()),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildSelectField(label: 'PROFISSIONAL', value: _selectedProfessionalName ?? 'Opcional', icon: Icons.badge_outlined, onTap: _showProfessionalSelector)),
                const SizedBox(width: 16),
                Expanded(child: _buildSelectField(label: 'CLIENTE', value: _selectedClientName ?? 'Opcional', icon: Icons.face_outlined, onTap: _showClientSelector)),
              ],
            ),
            const SizedBox(height: 20),

            _buildField(
              label: 'DESCRIÇÃO', 
              hint: 'Ex: Pagamento serviço unhas...', 
              controller: _descriptionController, 
              icon: Icons.notes,
              maxLines: 3,
            ),
            
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _transactionType == 'income' ? const Color(0xFFFFB6C1) : const Color(0xFF64748B), // Usando slate para despesas
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : Text(
                        _transactionType == 'income' ? 'REGISTRAR ENTRADA' : 'REGISTRAR SAÍDA',
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleItem(
              label: 'ENTRADA',
              isActive: _transactionType == 'income',
              activeColor: const Color(0xFFFFB6C1),
              onTap: () => setState(() => _transactionType = 'income'),
            ),
          ),
          Expanded(
            child: _toggleItem(
              label: 'SAÍDA',
              isActive: _transactionType == 'expense',
              activeColor: const Color(0xFF64748B),
              onTap: () => setState(() => _transactionType = 'expense'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem({required String label, required bool isActive, required Color activeColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isActive ? Colors.white : Colors.grey,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required String hint, required TextEditingController controller, required IconData icon, TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isLarge ? 24 : 16, color: isLarge ? const Color(0xFF1E293B) : Colors.black),
            decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal), border: InputBorder.none, icon: Icon(icon, color: const Color(0xFFFFB6C1), size: 20)),
          ),
        ),
      ],
    );
  }

  void _showPremiumPicker(String title, List<String> items, String currentValue, void Function(String?) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100], indent: 24, endIndent: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == currentValue;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    title: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, color: isSelected ? const Color(0xFFFFB6C1) : Colors.black87)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFFFB6C1)) : null,
                    onTap: () {
                      onSelected(item);
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

  Widget _buildDropdown({required String label, required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CATEGORIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showPremiumPicker(label, items, value, onChanged),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.category_outlined, color: Color(0xFFFFB6C1), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DATA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFFFFB6C1), size: 20),
                const SizedBox(width: 12),
                Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
