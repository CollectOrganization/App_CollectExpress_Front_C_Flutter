import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class AcompanharPedidoPage extends StatefulWidget {
  final String orderNumber;
  final int deliveryDay;
  final String deliveryPeriod;

  const AcompanharPedidoPage({
    super.key,
    required this.orderNumber,
    required this.deliveryDay,
    required this.deliveryPeriod,
  });

  @override
  State<AcompanharPedidoPage> createState() => _AcompanharPedidoPageState();
}

class _AcompanharPedidoPageState extends State<AcompanharPedidoPage> {
  bool _isRefreshing = false;

  Future<void> _refreshOrder() async {
    setState(() => _isRefreshing = true);

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isRefreshing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status do pedido atualizado.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshOrder,
          color: AppColors.green,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _PageHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Acompanhar Pedido',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Acompanhe cada etapa da sua locação',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _OrderHeaderCard(
                      orderNumber: widget.orderNumber,
                      isRefreshing: _isRefreshing,
                      onCopy: _copyOrderNumber,
                      onRefresh: _refreshOrder,
                    ),
                    const SizedBox(height: 20),
                    const _OrderProgressCard(),
                    const SizedBox(height: 20),
                    _DeliveryDetailsCard(
                      deliveryDay: widget.deliveryDay,
                      deliveryPeriod: widget.deliveryPeriod,
                    ),
                    const SizedBox(height: 20),
                    const _DumpsterCard(),
                    const SizedBox(height: 20),
                    _SupportCard(
                      onWhatsApp: _contactSupport,
                      onCancel: _requestCancellation,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 2),
    );
  }

  Future<void> _copyOrderNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.orderNumber));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Número do pedido copiado.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A integração com o WhatsApp será adicionada depois.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _requestCancellation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Solicitar cancelamento'),
          content: const Text(
            'Deseja solicitar o cancelamento deste pedido? '
            'A solicitação será analisada pela equipe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Voltar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Solicitar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitação de cancelamento enviada.'),
        backgroundColor: Colors.orange,
      ),
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
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                tooltip: 'Abrir menu',
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

class _OrderHeaderCard extends StatelessWidget {
  final String orderNumber;
  final bool isRefreshing;
  final VoidCallback onCopy;
  final VoidCallback onRefresh;

  const _OrderHeaderCard({
    required this.orderNumber,
    required this.isRefreshing,
    required this.onCopy,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sustainability,
        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.green,
            child: Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pedido em andamento',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar número',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _OrderProgressCard extends StatelessWidget {
  const _OrderProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status da Locação',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 22),
          _TrackingStep(
            icon: Icons.receipt_long_outlined,
            title: 'Pedido confirmado',
            subtitle: 'Pagamento aprovado',
            state: _TrackingState.completed,
          ),
          _TrackingStep(
            icon: Icons.inventory_2_outlined,
            title: 'Preparando a caçamba',
            subtitle: 'O fornecedor está preparando o equipamento',
            state: _TrackingState.current,
          ),
          _TrackingStep(
            icon: Icons.local_shipping_outlined,
            title: 'Em rota de entrega',
            subtitle: 'Você será avisado quando o motorista sair',
            state: _TrackingState.pending,
          ),
          _TrackingStep(
            icon: Icons.location_on_outlined,
            title: 'Caçamba entregue',
            subtitle: 'Aguardando entrega no endereço informado',
            state: _TrackingState.pending,
          ),
          _TrackingStep(
            icon: Icons.recycling_outlined,
            title: 'Coleta agendada',
            subtitle: 'A retirada será realizada ao final da locação',
            state: _TrackingState.pending,
            showLine: false,
          ),
        ],
      ),
    );
  }
}

enum _TrackingState { completed, current, pending }

class _TrackingStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _TrackingState state;
  final bool showLine;

  const _TrackingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    this.showLine = true,
  });

  @override
  Widget build(BuildContext context) {
    final completed = state == _TrackingState.completed;
    final current = state == _TrackingState.current;

    final color = completed || current ? AppColors.green : Colors.grey.shade400;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: current
                      ? AppColors.green
                      : completed
                      ? AppColors.green.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  child: Icon(
                    completed ? Icons.check : icon,
                    color: current ? Colors.white : color,
                    size: 19,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: completed ? AppColors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: state == _TrackingState.pending
                                ? Colors.black54
                                : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (current)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'AGORA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetailsCard extends StatelessWidget {
  final int deliveryDay;
  final String deliveryPeriod;

  const _DeliveryDetailsCard({
    required this.deliveryDay,
    required this.deliveryPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Detalhes da Entrega',
      children: [
        _InformationRow(
          icon: Icons.calendar_month_outlined,
          label: 'Data prevista',
          value: '$deliveryDay de outubro de 2024',
        ),
        const SizedBox(height: 14),
        _InformationRow(
          icon: Icons.schedule,
          label: 'Período',
          value: deliveryPeriod,
        ),
        const SizedBox(height: 14),
        const _InformationRow(
          icon: Icons.location_on_outlined,
          label: 'Endereço',
          value: 'Av. Paulista, 1000 - Bela Vista',
        ),
      ],
    );
  }
}

class _DumpsterCard extends StatelessWidget {
  const _DumpsterCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Serviço Contratado',
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/images/cacamba_5m.jpg',
                width: 92,
                height: 78,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    width: 92,
                    height: 78,
                    color: AppColors.lightGray,
                    child: const Icon(Icons.delete_outline),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caçamba 5m³ - Entulho',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Quantidade: 1 • Período: 3 dias',
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'R\$ 315,00',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onCancel;

  const _SupportCard({required this.onWhatsApp, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onWhatsApp,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF20C765),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text(
              'Falar com o Suporte',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text(
            'Solicitar cancelamento',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
