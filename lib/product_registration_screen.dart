import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fluunt_drawer.dart';

class ProductRegistrationScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  const ProductRegistrationScreen({super.key, this.onNavigation, this.userRole = 'agente'});

  @override
  State<ProductRegistrationScreen> createState() => _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  
  String _selectedCategory = 'Geral';
  bool _isSaving = false;

  final List<String> _categories = ['Geral', 'Cabelo', 'Corpo', 'Unhas', 'Maquiagem', 'Perfumes'];

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _salePriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o nome e o preço de venda.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'sku': _skuController.text.trim(),
        'costPrice': double.tryParse(_costPriceController.text) ?? 0.0,
        'salePrice': double.tryParse(_salePriceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'images': [], // Preparado para futuras imagens
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!')),
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
    _skuController.clear();
    _costPriceController.clear();
    _salePriceController.clear();
    _stockController.clear();
    setState(() {
      _selectedCategory = 'Geral';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: FluuntDrawer(
        selectedIndex: 5,
        onDestinationSelected: widget.onNavigation ?? (i) {},
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'NOVO PRODUTO',
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
              'Gestão de Inventário',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
            ),
            const SizedBox(height: 32),

            _buildDropdown(label: 'CATEGORIA', value: _selectedCategory, items: _categories, onChanged: (v) => setState(() => _selectedCategory = v!)),
            const SizedBox(height: 20),

            _buildField(label: 'NOME DO PRODUTO', hint: 'Nome do item', controller: _nameController, icon: Icons.shopping_bag_outlined),
            const SizedBox(height: 20),

            _buildField(label: 'SKU / CÓDIGO', hint: 'Identificador único (opcional)', controller: _skuController, icon: Icons.qr_code_scanner),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildField(label: 'PREÇO DE CUSTO (R\$)', hint: '0.00', controller: _costPriceController, icon: Icons.arrow_downward, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 16),
                Expanded(child: _buildField(label: 'PREÇO DE VENDA (R\$)', hint: '0.00', controller: _salePriceController, icon: Icons.payments_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 20),

            _buildField(label: 'ESTOQUE ATUAL', hint: '0', controller: _stockController, icon: Icons.inventory_2_outlined, keyboardType: TextInputType.number),
            
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
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
                        'SALVAR PRODUTO',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required String hint, required TextEditingController controller, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
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
                const Icon(Icons.category_outlined, color: Color(0xFFFFB6C1), size: 20),
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
