import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'client_registration_screen.dart';
import 'service_registration_screen.dart';
import 'staff_registration_screen.dart';
import 'product_registration_screen.dart';
import 'transaction_registration_screen.dart';
import 'financial_dashboard_screen.dart';
import 'staff_report_screen.dart';
import 'home_screen.dart';
import 'fluunt_drawer.dart';
import 'broadcast_screen.dart';
import 'product_sale_screen.dart';
import 'client_management_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler para notificações quando o app está fechado ou em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notificação em background: ${message.messageId}");
}

// Canal de Notificação para Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'Notificações Importantes', // title
  description: 'Este canal é usado para notificações importantes.', // description
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inicializa o Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializa Formatação de Data
    initializeDateFormatting('pt_BR', null);

    // Configuração básica do Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Inicializa notificações locais (sem travar se falhar)
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );
    } catch (e) {
      debugPrint("Erro ao inicializar notificações locais: $e");
    }

    // Solicita permissão assincronamente (não bloqueia o runApp)
    messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handlers
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Log do token (sem bloquear o startup)
    messaging.getToken().then((token) {
      debugPrint("\n--- FCM TOKEN ---");
      debugPrint("$token");
      debugPrint("-----------------\n");
    }).catchError((e) => debugPrint("Erro ao obter token FCM: $e"));

  } catch (e) {
    debugPrint("ERRO CRÍTICO NO STARTUP: $e");
  }

  runApp(const FluuntApp());
}

class FluuntApp extends StatelessWidget {
  const FluuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estúdio Alê',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    const Text('Ocorreu um erro de renderização:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(details.exception.toString(), style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        };
        return child!;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5B5B5),
          primary: const Color(0xFFE5B5B5),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1, color: Color(0xFF1E293B)),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _userRole = 'agente';
  String _userDisplayName = '...';

  @override
  void initState() {
    super.initState();
    // Pequeno delay para estabilizar o emulador antes de carregar dados
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _loadUserRole();
    });
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final email = (user.email ?? '').trim().toLowerCase();
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
          
      if (query.docs.isEmpty) {
        query = await FirebaseFirestore.instance
            .collection('staff')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
      }
      
      if (query.docs.isNotEmpty && mounted) {
        setState(() {
          final data = query.docs.first.data() as Map<String, dynamic>;
          _userRole = (data['role'] ?? 'agente').toString().toLowerCase().trim();
          _userDisplayName = data['name'] ?? 'Usuário';
          print("[MainScreen] Role: $_userRole, Name: $_userDisplayName");
        });
      } else if (mounted) {
        print("[MainScreen] Nenhum cargo encontrado para o email $email");
      }
    } catch (e) {
      print("[MainScreen] Erro ao carregar user role: $e");
    }
  }

  void _onItemSelected(int index) {
    if (!FluuntDrawer.isAllowed(_userRole, index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ Acesso restrito. Somente administradores.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Widget _buildCurrentScreen() {
    print("[MainScreen] Building screen for index: $_selectedIndex");
    switch (_selectedIndex) {
      case 0: return HomeScreen(onNavigation: _onItemSelected, userRole: _userRole, userName: _userDisplayName);
      case 1: return ReservationWizard(onNavigation: _onItemSelected, userRole: _userRole);
      case 2: return ClientRegistrationScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 3: return ServiceRegistrationScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 4: return StaffRegistrationScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 5: return ProductRegistrationScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 6: return TransactionRegistrationScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 7: return FinancialDashboardScreen(onNavigation: _onItemSelected, userRole: _userRole, userName: _userDisplayName);
      case 8: return StaffReportScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 9: return BroadcastScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 10: return ProductSaleScreen(onNavigation: _onItemSelected, userRole: _userRole);
      case 11: return ClientManagementScreen(onNavigation: _onItemSelected, userRole: _userRole);
      default: return HomeScreen(onNavigation: _onItemSelected, userRole: _userRole, userName: _userDisplayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }
}

class ReservationWizard extends StatefulWidget {
  final Function(int)? onNavigation;
  final String userRole;
  const ReservationWizard({super.key, this.onNavigation, this.userRole = 'agente'});

  @override
  State<ReservationWizard> createState() => _ReservationWizardState();
}

class _ReservationWizardState extends State<ReservationWizard> {
  int _currentStep = 1;

  // Form Data
  String? _selectedClient;
  String? _selectedProfessional;
  String? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  String _status = 'Agendado';
  double _price = 150.0;
  String? _selectedMarker;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  // Listas Dinâmicas do BD
  List<Map<String, dynamic>> _dbClients = [];
  List<Map<String, dynamic>> _dbStaff = [];
  List<Map<String, dynamic>> _dbServices = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final clientsSnap = await FirebaseFirestore.instance.collection('clients').get();
      final staffSnap = await FirebaseFirestore.instance.collection('staff').get();
      final servicesSnap = await FirebaseFirestore.instance.collection('services').get();

      setState(() {
        _dbClients = clientsSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        // Ordenação alfabética dos clientes
        _dbClients.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
        
        _dbStaff = staffSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _dbServices = servicesSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _nextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      setState(() => _isSaving = true);

      try {
        final clientItem = _dbClients.firstWhere((c) => c['name'] == _selectedClient, orElse: () => {});
        final staffItem = _dbStaff.firstWhere((s) => s['name'] == _selectedProfessional, orElse: () => {});
        final clientId = clientItem['id'] ?? '';
        final staffId = staffItem['id'] ?? '';
        final user = FirebaseAuth.instance.currentUser;

        await FirebaseFirestore.instance.collection('appointments').add({
          'cliente': _selectedClient,
          'clientId': clientId,
          'profissional': _selectedProfessional,
          'professionalId': staffId,
          'staffId': staffId, // Adicionando também staffId para compatibilidade com outros lugares
          'servico': _selectedService,
          'service': _selectedService,
          'data': _selectedDate.toIso8601String(),
          'status': _status,
          'valor': _price,
          'price': _price,
          'observacoes': _notesController.text,
          'creatorId': user?.uid ?? '',
          'creatorName': user?.email?.split('@')[0] ?? 'Admin',
          'dataCriacao': FieldValue.serverTimestamp(),
        });

        setState(() => _isSaving = false);
        _finishReservation();
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar no Firebase: $e')),
        );
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _finishReservation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Center(child: Icon(Icons.check_circle, color: Color(0xFFFFB6C1), size: 60)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reserva Confirmada!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 10),
            Text('A reserva para $_selectedClient foi agendada com sucesso.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentStep = 1;
                _selectedClient = null;
                _selectedService = null;
                _notesController.clear();
              });
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: FluuntDrawer(
        selectedIndex: 1,
        onDestinationSelected: widget.onNavigation ?? (i) {},
        userRole: widget.userRole,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text('NRESERVA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepDot(1),
                _buildStepDot(2),
                _buildStepDot(3),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Passo $_currentStep de 3', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB6C1), fontSize: 13, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(_getStepTitle(), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),
            _buildStepContent(),
            const SizedBox(height: 40),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(int step) {
    bool isActive = _currentStep == step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFB6C1) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Atendimento';
      case 2: return 'Agendamento';
      case 3: return 'Detalhes';
      default: return '';
    }
  }

  Widget _buildStepContent() {
    if (_isLoadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFFFFB6C1)),
        ),
      );
    }
    switch (_currentStep) {
      case 1: return _buildAtendimentoStep();
      case 2: return _buildAgendamentoStep();
      case 3: return _buildDetalhesStep();
      default: return Container();
    }
  }

  Widget _buildAtendimentoStep() {
    return Column(
      children: [
        _buildDropdown(
          label: 'CLIENTE',
          value: _selectedClient,
          items: _dbClients.map((c) => (c['name'] ?? 'Sem Nome').toString()).toList(),
          onChanged: (val) => setState(() => _selectedClient = val),
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'PROFISSIONAL',
          value: _selectedProfessional,
          items: _dbStaff.map((s) => (s['name'] ?? 'Sem Nome').toString()).toList(),
          onChanged: (val) => setState(() => _selectedProfessional = val),
          icon: Icons.content_cut_outlined,
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'SERVIÇO',
          value: _selectedService,
          items: _dbServices.map((s) => (s['name'] ?? 'Sem Nome').toString()).toList(),
          onChanged: (val) {
            setState(() {
              _selectedService = val;
              // Atualizar preço automaticamente
              final service = _dbServices.firstWhere((s) => s['name'] == val, orElse: () => {});
              if (service.containsKey('price')) {
                _price = (service['price'] as num).toDouble();
              }
            });
          },
          icon: Icons.spa_outlined,
        ),
      ],
    );
  }

  Widget _buildAgendamentoStep() {
    return Column(
      children: [
        _buildCustomField(
          label: 'DATA E HORA',
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedDate),
                );
                if (time != null) {
                  setState(() {
                    _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                }
              }
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFFFFB6C1)),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} às ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'STATUS',
          value: _status,
          items: ['Agendado', 'Confirmado', 'Pendente'],
          onChanged: (val) => setState(() => _status = val!),
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 20),
        _buildCustomField(
          label: 'VALOR (R\$)',
          child: Row(
            children: [
              const Text('R\$', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFB6C1))),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  onChanged: (val) => _price = double.tryParse(val) ?? 0,
                  controller: TextEditingController(text: _price.toStringAsFixed(2)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetalhesStep() {
    return Column(
      children: [
        _buildDropdown(
          label: 'MARCADOR (COMUNICAÇÃO)',
          value: _selectedMarker,
          items: ['⚠️ Importante', '⏳ Pendente', '✅ Sucesso'],
          onChanged: (val) => setState(() => _selectedMarker = val),
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 20),
        _buildCustomField(
          label: 'OBSERVAÇÕES INTERNAS',
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Adicione comentários sobre o atendimento...',
              border: InputBorder.none,
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required Function(String?) onChanged, required IconData icon}) {
    return _buildCustomField(
      label: label,
      child: InkWell(
        onTap: () => _showPremiumPicker(label, items, value, onChanged),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB6C1), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? 'Selecionar $label',
                style: TextStyle(
                  fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                  color: value != null ? Colors.black : Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  void _showPremiumPicker(String title, List<String> items, String? currentValue, Function(String?) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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

  Widget _buildCustomField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Text('VOLTAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: (_currentStep == 1 && (_selectedClient == null || _selectedProfessional == null || _selectedService == null)) || _isSaving ? null : _nextStep,
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
                : Text(
                    _currentStep == 3 ? 'CONFIRMAR RESERVA' : 'PRÓXIMO',
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
          ),
        ),
      ],
    );
  }
}
