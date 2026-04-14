import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class FluuntDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final String userRole;

  const FluuntDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.userRole = 'agente',
  });

  String _getUserDisplayName() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Estúdio Alê';
      if (user.displayName != null && user.displayName!.isNotEmpty) return user.displayName!;
      final email = user.email ?? '';
      final namePart = email.split('@').first.replaceAll('.', ' ');
      return namePart.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    } catch (e) {
      return 'Usuário';
    }
  }

  // Páginas que o AGENTE pode acessar
  static const Set<int> _agentPages = {
    0,  // Início
    1,  // Nova Reserva
    5,  // Produtos (visualizar)
    9,  // Mensagens WhatsApp
    10, // Vender Produto
    11, // Gerenciar Clientes
  };

  static bool isAllowed(String role, int index) {
    final r = role.toLowerCase().trim();
    if (r == 'administrador' || r == 'admin') return true;
    return _agentPages.contains(index);
  }

  @override
  Widget build(BuildContext context) {
    final role = userRole.toLowerCase().trim();
    final isAdmin = role == 'administrador' || role == 'admin';
    final roleBadge = isAdmin ? '👑 Admin' : '👤 Agente';

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFE5B5B5)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text('Estúdio Alê',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_getUserDisplayName(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(roleBadge,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Páginas de todos (agente + admin)
          _buildItem(context, 0, Icons.home_rounded, 'Início', true),
          _buildItem(context, 1, Icons.calendar_today, 'Nova Reserva', true),

          // Páginas somente Admin
          if (isAdmin) _buildItem(context, 2, Icons.person_add, 'Cadastrar Cliente', true),
          if (isAdmin) _buildItem(context, 3, Icons.room_service, 'Cadastrar Serviço', true),
          if (isAdmin) _buildItem(context, 4, Icons.badge, 'Equipe', true),

          _buildItem(context, 5, Icons.inventory_2, 'Produtos', true),

          // Financeiro somente admin
          if (isAdmin) _buildItem(context, 6, Icons.account_balance_wallet, 'Financeiro', true),
          if (isAdmin) _buildItem(context, 7, Icons.dashboard_outlined, 'Dashboard', true),
          if (isAdmin) _buildItem(context, 8, Icons.bar_chart_rounded, 'Produção', true),

          _buildItem(context, 9, Icons.chat_bubble_outline_rounded, 'Mensagens WhatsApp', true),
          _buildItem(context, 10, Icons.shopping_basket_outlined, 'Vender Produto', true),
          _buildItem(context, 11, Icons.people_rounded, 'Gerenciar Clientes', true),

          const Divider(height: 40, indent: 20, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              Navigator.of(context).pop(); // fecha o drawer primeiro
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, IconData icon, String label, bool enabled) {
    final isSelected = selectedIndex == index;
    const activeColor = Color(0xFFE5B5B5); 
    
    return ListTile(
      leading: Icon(icon, color: isSelected ? activeColor : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : Colors.black87)),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); 
        onDestinationSelected(index);
      },
    );
  }
}
