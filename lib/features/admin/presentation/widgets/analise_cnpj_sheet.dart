import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/usuario.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/admin_repository.dart';
import '../../domain/models/analise_cnpj.dart';

/// Abre a análise do CNPJ de [usuario] (dados da Receita + IA).
///
/// Num cadastro pendente, o admin pode aprovar ou recusar dali mesmo: o
/// sheet devolve o status escolhido, ou `null` se só fechou.
Future<StatusUsuario?> showAnaliseCnpjSheet(
  BuildContext context,
  Usuario usuario,
) {
  return showModalBottomSheet<StatusUsuario>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AnaliseCnpjSheet(usuario: usuario),
  );
}

class AnaliseCnpjSheet extends ConsumerStatefulWidget {
  final Usuario usuario;

  const AnaliseCnpjSheet({super.key, required this.usuario});

  @override
  ConsumerState<AnaliseCnpjSheet> createState() => _AnaliseCnpjSheetState();
}

class _AnaliseCnpjSheetState extends ConsumerState<AnaliseCnpjSheet> {
  AnaliseCnpj? _analise;
  Object? _erro;
  bool _carregando = true;

  /// Gerando uma análise nova (Receita + LLM), não só lendo a salva.
  bool _gerando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final salva = await ref
          .read(adminRepositoryProvider)
          .analiseCnpjSalva(widget.usuario.id);
      if (!mounted) return;

      if (salva == null) {
        await _gerar();
        return;
      }

      setState(() {
        _analise = salva;
        _carregando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error;
        _carregando = false;
      });
    }
  }

  Future<void> _gerar() async {
    setState(() {
      _carregando = true;
      _gerando = true;
      _erro = null;
    });

    try {
      final nova = await ref
          .read(adminRepositoryProvider)
          .gerarAnaliseCnpj(widget.usuario.id);
      if (!mounted) return;
      setState(() => _analise = nova);
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = error);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
          _gerando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendente = widget.usuario.status == StatusUsuario.pendente;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Análise do CNPJ com IA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.usuario.nomeCompleto,
                          style: const TextStyle(color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _conteudo(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _carregando ? null : _gerar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refazer análise'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.green,
                    ),
                  ),
                  if (pendente)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context, StatusUsuario.suspenso),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Recusar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, StatusUsuario.ativo),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aprovar'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.green),
            const SizedBox(height: 16),
            Text(
              _gerando
                  ? 'Consultando a Receita Federal e analisando com IA...'
                  : 'Carregando a análise...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (_gerando) ...[
              const SizedBox(height: 4),
              const Text(
                'Pode levar alguns segundos.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      );
    }

    final analise = _analise;

    if (_erro != null || analise == null) {
      final mensagem = _erro is ApiException
          ? (_erro as ApiException).message
          : 'Não foi possível carregar a análise.';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Colors.black38),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: _gerar, child: const Text('Tentar de novo')),
          ],
        ),
      );
    }

    return _AnaliseView(analise: analise);
  }
}

class _AnaliseView extends StatelessWidget {
  final AnaliseCnpj analise;

  const _AnaliseView({required this.analise});

  @override
  Widget build(BuildContext context) {
    final dados = analise.dadosReceita;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CabecalhoNota(analise: analise),
        if (!analise.iaUsada && analise.nota == null)
          _Aviso(
            texto:
                analise.motivoSemIa ??
                'A análise de texto com IA não rodou nesta vez.',
          ),
        if (dados != null)
          _Secao(
            titulo: 'Dados da Receita Federal',
            children: [
              _Campo('Razão social', dados.razaoSocial),
              if (dados.nomeFantasia.isNotEmpty)
                _Campo('Nome fantasia', dados.nomeFantasia),
              _Campo('CNPJ', analise.cnpj),
              _Campo('Situação', dados.situacaoCadastral),
              _Campo('Abertura', formatDate(dados.dataInicioAtividade)),
              if (dados.municipio.isNotEmpty)
                _Campo('Cidade', '${dados.municipio}/${dados.uf}'),
              if (dados.cnaePrincipal != null)
                _Campo(
                  'Atividade principal',
                  '${dados.cnaePrincipal!.codigo} · '
                      '${dados.cnaePrincipal!.descricao}',
                ),
              for (final cnae in dados.cnaesSecundarios.take(4))
                _Campo('Secundária', '${cnae.codigo} · ${cnae.descricao}'),
              if (dados.cnaesSecundarios.length > 4)
                Text(
                  '+ ${dados.cnaesSecundarios.length - 4} atividades secundárias',
                  style: const TextStyle(color: Colors.black54),
                ),
            ],
          ),
        if (analise.checagens.isNotEmpty)
          _Secao(
            titulo: 'Como a nota foi calculada',
            children: [
              for (final checagem in analise.checagens)
                _LinhaChecagem(checagem: checagem),
            ],
          ),
        if (analise.atividade != null)
          _Secao(
            titulo: 'Atividade x perfil (IA)',
            children: [
              Text(analise.atividade!.justificativa),
              if (analise.cnaesCompativeis.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final codigo in analise.cnaesCompativeis)
                      Chip(
                        label: Text(codigo),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.sustainability,
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ],
          ),
        if (analise.nome != null)
          _Secao(
            titulo: 'Nome do cadastro x Receita (IA)',
            children: [Text(analise.nome!.justificativa)],
          ),
        if (analise.pontosDeAtencao.isNotEmpty)
          _Secao(
            titulo: 'Pontos de atenção',
            children: [
              for (final ponto in analise.pontosDeAtencao)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2, right: 6),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                      Expanded(child: Text(ponto)),
                    ],
                  ),
                ),
            ],
          ),
        if (analise.parecer.isNotEmpty)
          _Secao(
            titulo: analise.iaUsada ? 'Parecer da IA' : 'Parecer',
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sustainability,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(analise.parecer),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Text(
          [
            if (analise.fonte != null)
              'Fonte: ${analise.fonte} (Receita Federal)',
            if (analise.modelo != null) 'IA: ${analise.modelo}',
            if (analise.geradoEm != null)
              'Gerada em ${formatDate(analise.geradoEm)} às '
                  '${_hora(analise.geradoEm!)}',
          ].join(' · '),
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 4),
        const Text(
          'A IA recomenda; a decisão de aprovar é do administrador.',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }

  static String _hora(DateTime data) {
    final local = data.toLocal();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}

Color _corDa(RecomendacaoCnpj recomendacao) {
  return switch (recomendacao) {
    RecomendacaoCnpj.aprovar => AppColors.green,
    RecomendacaoCnpj.revisar => Colors.orange.shade700,
    RecomendacaoCnpj.reprovar => Colors.red,
  };
}

class _CabecalhoNota extends StatelessWidget {
  final AnaliseCnpj analise;

  const _CabecalhoNota({required this.analise});

  @override
  Widget build(BuildContext context) {
    final cor = _corDa(analise.recomendacao);
    final nota = analise.nota;

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cor, width: 4),
          ),
          child: Semantics(
            label: nota == null ? 'Sem nota' : 'Nota $nota de 10',
            child: ExcludeSemantics(
              child: Text(
                nota == null
                    ? '–'
                    : nota.toStringAsFixed(1).replaceAll('.', ','),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: cor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  analise.recomendacao.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                analise.resumo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Secao({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _Campo(this.rotulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$rotulo: ',
              style: const TextStyle(color: Colors.black54),
            ),
            TextSpan(
              text: valor.isEmpty ? '-' : valor,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaChecagem extends StatelessWidget {
  final ChecagemCnpj checagem;

  const _LinhaChecagem({required this.checagem});

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = switch (checagem.ok) {
      true => (Icons.check_circle, AppColors.green),
      false => (Icons.cancel, Colors.red),
      null => (Icons.remove_circle_outline, Colors.black38),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checagem.item,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  checagem.resultado,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          if (checagem.maximo > 0)
            Text(
              '${checagem.pontos}/${checagem.maximo}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}
