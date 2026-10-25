import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class PerfilClientePage extends StatefulWidget {
  const PerfilClientePage({super.key});

  @override
  State<PerfilClientePage> createState() => _PerfilClientePageState();
}

class _PerfilClientePageState extends State<PerfilClientePage> {
  String name = 'João da Silva';
  String email = 'joao.silva@email.com';
  String phone = '(11) 99999-9999';

  String street = 'Avenida Paulista, 1000';
  String complement = 'Apto. 82';
  String neighborhood = 'Bela Vista';
  String city = 'São Paulo';
  String state = 'SP';
  String cep = '01311-200';

  bool orderNotifications = true;
  bool offerNotifications = true;
  bool whatsappNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _PageHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 34),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Meu Perfil',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gerencie seus dados e preferências da conta',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  _ProfileCard(name: name, onEdit: _editPersonalData),
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: 'Dados pessoais',
                    onEdit: _editPersonalData,
                  ),
                  const SizedBox(height: 10),
                  _PersonalDataCard(email: email, phone: phone),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Endereço principal',
                    onEdit: _editAddress,
                  ),
                  const SizedBox(height: 10),
                  _AddressCard(
                    street: street,
                    complement: complement,
                    neighborhood: neighborhood,
                    city: city,
                    state: state,
                    cep: cep,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Conta e preferências',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _PreferencesCard(
                    onPassword: _changePassword,
                    onNotifications: _configureNotifications,
                    onPayments: _showPayments,
                    onSupport: _showSupport,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sair da conta',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: _SustainabilityFooter()),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 3),
    );
  }

  Future<void> _editPersonalData() async {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar dados pessoais'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        name = nameController.text.trim();
        email = emailController.text.trim();
        phone = phoneController.text.trim();
      });

      _showMessage('Dados atualizados com sucesso.');
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _editAddress() async {
    final streetController = TextEditingController(text: street);
    final complementController = TextEditingController(text: complement);
    final neighborhoodController = TextEditingController(text: neighborhood);
    final cityController = TextEditingController(text: city);
    final stateController = TextEditingController(text: state);
    final cepController = TextEditingController(text: cep);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar endereço'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cepController,
                  decoration: const InputDecoration(labelText: 'CEP'),
                ),
                TextField(
                  controller: streetController,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                ),
                TextField(
                  controller: complementController,
                  decoration: const InputDecoration(labelText: 'Complemento'),
                ),
                TextField(
                  controller: neighborhoodController,
                  decoration: const InputDecoration(labelText: 'Bairro'),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        street = streetController.text.trim();
        complement = complementController.text.trim();
        neighborhood = neighborhoodController.text.trim();
        city = cityController.text.trim();
        state = stateController.text.trim();
        cep = cepController.text.trim();
      });

      _showMessage('Endereço atualizado.');
    }

    streetController.dispose();
    complementController.dispose();
    neighborhoodController.dispose();
    cityController.dispose();
    stateController.dispose();
    cepController.dispose();
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alterar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
              ),
              TextField(
                controller: confirmationController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valid =
                    passwordController.text.length >= 6 &&
                    passwordController.text == confirmationController.text;

                if (valid) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Alterar'),
            ),
          ],
        );
      },
    );

    if (saved == true && mounted) {
      _showMessage('Senha alterada com sucesso.');
    }

    passwordController.dispose();
    confirmationController.dispose();
  }

  Future<void> _configureNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Notificações',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Atualizações de pedidos'),
                      value: orderNotifications,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        setState(() => orderNotifications = value);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ofertas e promoções'),
                      value: offerNotifications,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        setState(() => offerNotifications = value);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mensagens pelo WhatsApp'),
                      value: whatsappNotifications,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        setState(() => whatsappNotifications = value);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPayments() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formas de pagamento',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.pix, color: AppColors.green),
                  title: Text('PIX'),
                  subtitle: Text('Pagamento instantâneo'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.credit_card, color: AppColors.green),
                  title: Text('Cartão de crédito'),
                  subtitle: Text('Nenhum cartão cadastrado'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSupport() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.chat_outlined, color: AppColors.green),
                  title: Text('WhatsApp'),
                  subtitle: Text('(11) 99999-9999'),
                ),
                ListTile(
                  leading: Icon(Icons.email_outlined, color: AppColors.green),
                  title: Text('E-mail'),
                  subtitle: Text('suporte@collectxpress.com.br'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja encerrar sua sessão?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.green),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(scaffoldContext).openEndDrawer();
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  minimumSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.menu_rounded),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final VoidCallback onEdit;

  const _ProfileCard({required this.name, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.sustainability,
        border: Border.all(color: const Color(0xFF83AC55)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final identity = Row(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.green,
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 55,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const _VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Cliente • Desde outubro de 2024',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3 pedidos realizados   •   1 pedido em andamento',
                      style: TextStyle(
                        color: Color(0xFF267A2D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                identity,
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar perfil'),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, color: AppColors.green, size: 15),
          SizedBox(width: 4),
          Text(
            'Conta verificada',
            style: TextStyle(
              color: Color(0xFF267A2D),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;

  const _SectionHeader({required this.title, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: const Text('Editar'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF267A2D),
            backgroundColor: AppColors.lightGray,
          ),
        ),
      ],
    );
  }
}

class _PersonalDataCard extends StatelessWidget {
  final String email;
  final String phone;

  const _PersonalDataCard({required this.email, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 40,
        runSpacing: 20,
        children: [
          _DataItem(icon: Icons.email_outlined, label: 'E-mail', value: email),
          const _DataItem(
            icon: Icons.badge_outlined,
            label: 'CPF',
            value: '***.456.789-**',
          ),
          _DataItem(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: phone,
          ),
        ],
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green, size: 20),
          const SizedBox(height: 15),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String street;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;

  const _AddressCard({
    required this.street,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.green,
            size: 30,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  street,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$complement • $neighborhood, $city - $state',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 7),
                Text(
                  'CEP $cep',
                  style: const TextStyle(
                    color: Color(0xFF267A2D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const _DefaultBadge(),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sustainability,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Padrão',
        style: TextStyle(
          color: Color(0xFF267A2D),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final VoidCallback onPassword;
  final VoidCallback onNotifications;
  final VoidCallback onPayments;
  final VoidCallback onSupport;

  const _PreferencesCard({
    required this.onPassword,
    required this.onNotifications,
    required this.onPayments,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _PreferenceItem(
            icon: Icons.lock_outline,
            title: 'Alterar senha',
            subtitle: 'Atualizada há 3 meses',
            onTap: onPassword,
          ),
          _PreferenceItem(
            icon: Icons.notifications_none,
            title: 'Notificações',
            subtitle: 'Pedidos e ofertas ativados',
            onTap: onNotifications,
          ),
          _PreferenceItem(
            icon: Icons.credit_card_outlined,
            title: 'Formas de pagamento',
            subtitle: 'Gerencie cartões e PIX',
            onTap: onPayments,
          ),
          _PreferenceItem(
            icon: Icons.help_outline,
            title: 'Ajuda e suporte',
            subtitle: 'Fale com a equipe Collect Xpress',
            onTap: onSupport,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _PreferenceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.green.withValues(alpha: 0.07),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.sustainability,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.green),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
            ),
            if (showDivider)
              const Divider(height: 1, indent: 68, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

class _SustainabilityFooter extends StatelessWidget {
  const _SustainabilityFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sustainability,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 30),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Text(
                'Descarte Sustentável',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Todas as nossas caçambas seguem rigorosamente as normas '
            'ambientais municipais e resoluções do CONAMA.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            '☎  Suporte WhatsApp: (11) 99999-9999',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
