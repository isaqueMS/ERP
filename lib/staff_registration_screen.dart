import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fluunt_drawer.dart';

class StaffRegistrationScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  const StaffRegistrationScreen({super.key, this.onNavigation, this.userRole = 'agente'});

  @override
  State<StaffRegistrationScreen> createState() => _StaffRegistrationScreenState();
}

class _StaffRegistrationScreenState extends State<StaffRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  
  String _selectedRole = 'agente';
  String _selectedStatus = 'active';
  
  final List<String> _availableCategories = ['Unhas', 'Cabelo', 'Estética', 'Sobrancelha', 'Massagem'];
  final List<String> _selectedCategories = [];
  
  bool _isSaving = false;

  Future<void> _saveStaff() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _commissionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha os campos obrigatórios.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('staff').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone': _phoneController.text.trim(),
        'commission': int.tryParse(_commissionController.text) ?? 0,
        'role': _selectedRole,
        'status': _selectedStatus,
        'enabledCategories': _selectedCategories,
        'specialties': _selectedCategories, // Por padrão, especialidades = categorias habilitadas
        'specialty': _selectedCategories.isNotEmpty ? _selectedCategories.first : "",
        'photoUrl': "",
        'uid': DateTime.now().millisecondsSinceEpoch.toString(), // UID simulado
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionária cadastrada com sucesso!')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _commissionController.clear();
    setState(() {
      _selectedCategories.clear();
      _selectedRole = 'agente';
      _selectedStatus = 'active';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: FluuntDrawer(
        selectedIndex: 4,
        onDestinationSelected: widget.onNavigation ?? (i) {},
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'NOVA FUNCIONÁRIA',
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
              'Gestão de Equipe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
            ),
            const SizedBox(height: 32),

            _buildField(label: 'NOME COMPLETO', hint: 'Nome da profissional', controller: _nameController, icon: Icons.badge_outlined),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildField(label: 'E-MAIL', hint: 'bruna@fluunt.com', controller: _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(label: 'SENHA', hint: '123456', controller: _passwordController, icon: Icons.lock_outline, isPassword: true)),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildField(label: 'TELEFONE', hint: '71999999999', controller: _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(label: 'COMISSÃO (%)', hint: '50', controller: _commissionController, icon: Icons.percent, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildDropdown(label: 'CARGO', value: _selectedRole, items: ['agente', 'administrador'], onChanged: (v) => setState(() => _selectedRole = v!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown(label: 'STATUS', value: _selectedStatus, items: ['active', 'inactive'], onChanged: (v) => setState(() => _selectedStatus = v!))),
              ],
            ),
            const SizedBox(height: 32),

            const Text('ESPECIALIDADES / CATEGORIAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) _selectedCategories.add(cat);
                      else _selectedCategories.remove(cat);
                    });
                  },
                  selectedColor: const Color(0xFFFFB6C1).withOpacity(0.2),
                  checkmarkColor: const Color(0xFFFFB6C1),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFFFFB6C1) : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB6C1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  shadowColor: const Color(0xFFFFB6C1).withOpacity(0.4),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        'SALVAR FUNCIONÁRIA',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required String hint, required TextEditingController controller, required IconData icon, TextInputType keyboardType = TextInputType.text, bool isPassword = false}) {
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
            obscureText: isPassword,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showPremiumPicker(label, items, value, onChanged),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(label == 'CARGO' ? Icons.work_outline : Icons.info_outline, color: const Color(0xFFFFB6C1), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
}
