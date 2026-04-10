# 🌟 ERP Estúdio Alê | Management & CRM System

Bem-vindo ao repositório oficial do **ERP do Estúdio Alê**. 
Este projeto é uma solução completa desenvolvida em **Flutter**, projetada especificamente para otimizar a gestão operacional, financeira e de relacionamento com clientes em salões de beleza e estúdios de estética.

---

## 📱 Visão Geral

O aplicativo oferece uma interface elegante e fluida para o controle de todas as esferas de um negócio moderno. Dentre os diferenciais do sistema, destaca-se a integração **Real-time** através do banco de dados Firebase, automação de mensagens via WhatsApp API para lembretes de serviços, e robusto Role-Based Access Control (RBAC) para gerenciar o que os membros da equipe podem ver e acessar.

## ✨ Principais Funcionalidades

- **Controle de Acesso Modular (RBAC) 🔐**
  - **Admin**: Acesso total ao faturamento, métricas sensíveis (Dashboard, Produção), equipe e opções de sistema avançadas.
  - **Agentes**: Interface restrita com foco operacional (Início, Agendamentos, Venda Rápida e Relacionamento via WhatsApp).
  
- **Gerenciamento de Clientes Avançado (CRM) 👥**
  - Cadastro detalhado com perfil de acesso rápido e histórico completo de interações (compras e serviços).
  - Consulta automática de consumo e visitas ao longo do tempo.

- **Fluxo de Agendamento em Etapas (Wizard) 🗓️**
  - Formulário intuitivo de passo-a-passo (Wizard Interface) que resolve conflitos de layout e evita perda de dados antes de submeter no Firebase.

- **Integração WhatsApp API 💬**
  - Disparo de mensagens proativas do próprio aplicativo para a confirmação de horário, notas fiscais ou comunicados (texto livre utilizando a Official API da Meta).

- **Gestão Financeira e Estoque 💰**
  - Controle de fluxo de caixa, comissões individuais para cada staff do estúdio e venda de produtos com contagem de estoque.
  
- **Push Notifications 🔔**
  - Serviço ativo de Background via *Firebase Cloud Messaging* com alertas e notificações imediatas da equipe ou sistema.

---

## 🚀 Tecnologias Utilizadas

Este projeto foi construído sobre uma Stack moderna e totalmente Mobile-first para garantir rapidez e escalabilidade:

- **Frontend Core:** [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/) (Suporte Material 3)
- **Backend as a Service:** [Firebase](https://firebase.google.com/)
  - **Authentication:** Gerenciamento seguro de staff.
  - **Firestore:** Banco de dados NoSQL pautado em alta disponibilidade e sincronização em tempo real.
  - **Cloud Messaging:** Integração ativa para Push Notifications locais e remotas.
- **Integração Externa:** Meta for Developers (WhatsApp Webhooks/Cloud API)
- **Localização:** Componentes `flutter_localizations` formatados para PT-BR e moedas em `BRL`.

---

## ⚙️ Pré-Requisitos e Setup

Caso você deseje clonar e rodar o aplicativo localmente, as seguintes ferramentas devem estar instaladas na sua estrutura de desenvolvimento:

1. [SDK do Flutter](https://docs.flutter.dev/get-started/install) atualizado na branch *stable*.
2. Um emulador (Android SDK/AVD) ou dispositivo físico sincronizado para depuração.
3. [SDK do Java/Android Command-line Tools](https://developer.android.com/studio)

### 📲 Inicializando o App

Clone este repositório para o seu sistema e resolva as dependências:

```bash
git clone https://github.com/isaqueMS/ERP.git
cd ERP
flutter pub get
```

Gere o artefato da versão ou instale a aplicação conectada a um depurador:

```bash
# Debug & Hot Reload
flutter run

# Compilação nativa da Release (Android APK)
flutter build apk --release
```

---

## 🔒 Considerações de Segurança
Por se tratar de um sistema unificado aos serviços Google via Firebase, garanta que os arquivos confidenciais do projeto, como o **`google-services.json`** e os Tokens temporários da API da Meta gerados no painel (App), estejam listados e omitidos no seu `.gitignore` e não sejam publicados.

---
*Desenvolvido focado em Performance e Excelência em Processos (Business Intelligence).*
