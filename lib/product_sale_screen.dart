import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fluunt_drawer.dart';

class ProductSaleScreen extends StatefulWidget {
  final Function(int)? onNavigation;
  const ProductSaleScreen({super.key, this.onNavigation});

  @override
  State<ProductSaleScreen> createState() => _ProductSaleScreenState();
}

class _ProductSaleScreenState extends State<ProductSaleScreen> {
  final _firestore = FirebaseFirestore.instance;
  
  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedProductId;
  String? _selectedProductName;
  double _productPrice = 0.0;
  int _quantity = 1;
  bool _isLoading = false;

  static const _textPrimary = Color(0xFF4A3434);
  static const _roseGold = Color(0xFFE5B5B5);
  static const _quartz = Color(0xFFFCE7E7);
  static const _bg = Color(0xFFFFFFFF);

  Future<void> _processSale() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um produto'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final total = _productPrice * _quantity;
      
      // 1. Registrar a Venda
      await _firestore.collection('sales').add({
        'clientId': _selectedClientId,
        'clientName': _selectedClientName ?? 'Consumidor Final',
        'productId': _selectedProductId,
        'productName': _selectedProductName,
        'price': _productPrice,
        'quantity': _quantity,
        'total': total,
        'date': Timestamp.now(),
      });

      // 2. Registrar na Contabilidade (Transactions)
      await _firestore.collection('transactions').add({
        'title': 'Venda: $_selectedProductName',
        'category': 'Venda de Produto',
        'amount': total,
        'type': 'income', // Entrada
        'date': Timestamp.now(),
        'description': 'Venda de $_quantity unidade(s) para ${_selectedClientName ?? "Consumidor"}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda realizada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar venda: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: FluuntDrawer(selectedIndex: 10, onDestinationSelected: widget.onNavigation ?? (i) {}),
      appBar: AppBar(
        title: const Text('Nova Venda', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O que você está vendendo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textPrimary)),
            const SizedBox(height: 20),
            
            // Seleção de Produto
            _buildProductSelector(),
            
            const SizedBox(height: 24),
            const Text('Para quem?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
            const SizedBox(height: 12),
            
            // Seleção de Cliente
            _buildClientSelector(),

            const SizedBox(height: 32),
            _buildSummaryCard(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CONFIRMAR VENDA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final products = snapshot.data!.docs;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _quartz.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Selecione o Produto'),
              value: _selectedProductId,
              items: products.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc['name']),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  final selectedDoc = products.firstWhere((doc) => doc.id == v);
                  final data = selectedDoc.data() as Map<String, dynamic>;
                  setState(() {
                    _selectedProductId = v;
                    _selectedProductName = data['name'] ?? '';
                    _productPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('clients').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final clients = snapshot.data!.docs;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _quartz.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Selecionar Cliente (Opcional)'),
              value: _selectedClientId,
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Consumidor Final')),
                ...clients.map((doc) {
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(doc['name']),
                  );
                }),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedClientId = v;
                  if (v != null) {
                    final selectedDoc = clients.firstWhere((doc) => doc.id == v);
                    _selectedClientName = selectedDoc['name'];
                  } else {
                    _selectedClientName = 'Consumidor Final';
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _textPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quantidade', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: _roseGold),
                    onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                  ),
                  Text('$_quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: _roseGold),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL DA VENDA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                'R\$ ${(_productPrice * _quantity).toStringAsFixed(2)}',
                style: const TextStyle(color: _roseGold, fontWeight: FontWeight.w900, fontSize: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
