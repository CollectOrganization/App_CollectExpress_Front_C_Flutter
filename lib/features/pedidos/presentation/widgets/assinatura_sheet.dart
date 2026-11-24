import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tamanho da imagem enviada à API. A API aceita PNG de 100x40 até
/// 2000x1000 px e até 300 KB; 600x240 fica longe desses limites.
const _larguraExportada = 600;
const _alturaExportada = 240;

/// Espessura do traço na tela. Na imagem exportada ela é proporcional.
const _espessuraTraco = 3.0;

/// Comprimento mínimo (em px da tela) para o desenho valer como assinatura.
const _comprimentoMinimo = 40.0;

/// Abre o modal para o cliente desenhar a assinatura do contrato.
///
/// Devolve o PNG em base64 (sem prefixo `data:`), pronto para o campo
/// `assinatura_base64` do checkout, ou `null` se o usuário desistir.
Future<String?> mostrarAssinaturaSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    // Arrastar para assinar não pode fechar a folha.
    enableDrag: false,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const _AssinaturaSheet(),
  );
}

class _AssinaturaSheet extends StatefulWidget {
  const _AssinaturaSheet();

  @override
  State<_AssinaturaSheet> createState() => _AssinaturaSheetState();
}

class _AssinaturaSheetState extends State<_AssinaturaSheet> {
  final List<List<Offset>> _tracos = [];

  /// Tamanho da área de desenho na tela, usado para escalar a exportação.
  Size _areaDeDesenho = Size.zero;

  bool _exportando = false;
  String? _erro;

  bool get _assinado {
    var comprimento = 0.0;

    for (final traco in _tracos) {
      for (var i = 1; i < traco.length; i++) {
        comprimento += (traco[i] - traco[i - 1]).distance;
      }
    }

    return comprimento >= _comprimentoMinimo;
  }

  Offset _dentroDaArea(Offset ponto) {
    return Offset(
      ponto.dx.clamp(0.0, _areaDeDesenho.width).toDouble(),
      ponto.dy.clamp(0.0, _areaDeDesenho.height).toDouble(),
    );
  }

  void _iniciarTraco(Offset ponto) {
    setState(() {
      _erro = null;
      _tracos.add([_dentroDaArea(ponto)]);
    });
  }

  void _continuarTraco(Offset ponto) {
    if (_tracos.isEmpty) return;

    setState(() => _tracos.last.add(_dentroDaArea(ponto)));
  }

  void _limpar() {
    setState(() {
      _erro = null;
      _tracos.clear();
    });
  }

  Future<void> _confirmar() async {
    if (!_assinado || _exportando || _areaDeDesenho.isEmpty) return;

    setState(() => _exportando = true);

    try {
      final assinatura = await _exportarPng();

      if (!mounted) return;

      Navigator.of(context).pop(assinatura);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _exportando = false;
        _erro = 'Não foi possível gerar a assinatura. Tente novamente.';
      });
    }
  }

  /// Redesenha os traços em fundo branco, no tamanho fixo da API.
  Future<String> _exportarPng() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        _larguraExportada.toDouble(),
        _alturaExportada.toDouble(),
      ),
      Paint()..color = Colors.white,
    );
    canvas.scale(_larguraExportada / _areaDeDesenho.width);
    _desenharTracos(canvas, _tracos);

    final imagem = await recorder.endRecording().toImage(
      _larguraExportada,
      _alturaExportada,
    );

    try {
      final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);

      if (dados == null) throw StateError('PNG não gerado.');

      return base64Encode(dados.buffer.asUint8List());
    } finally {
      imagem.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assinatura do contrato',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ao assinar, você aceita os termos e condições do contrato de '
              'locação de caçamba. O contrato assinado será gerado em PDF e '
              'enviado por e-mail para você e para o caçambeiro responsável '
              'pela caçamba alugada.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Desenhe sua assinatura no quadro abaixo:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: _larguraExportada / _alturaExportada,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _areaDeDesenho = constraints.biggest;

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) => _iniciarTraco(d.localPosition),
                        onPanUpdate: (d) => _continuarTraco(d.localPosition),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _AssinaturaPainter(_tracos),
                          child: _tracos.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Assine aqui',
                                    style: TextStyle(
                                      color: Colors.black26,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _exportando || _tracos.isEmpty ? null : _limpar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Limpar'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _exportando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _assinado && !_exportando ? _confirmar : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.green.withValues(
                      alpha: 0.4,
                    ),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _exportando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Assinar e aceitar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha os traços (tela e exportação usam o mesmo código).
void _desenharTracos(Canvas canvas, List<List<Offset>> tracos) {
  final tinta = Paint()
    ..color = Colors.black
    ..strokeWidth = _espessuraTraco
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  for (final traco in tracos) {
    if (traco.length == 1) {
      canvas.drawCircle(
        traco.first,
        _espessuraTraco / 2,
        tinta..style = PaintingStyle.fill,
      );
      tinta.style = PaintingStyle.stroke;
      continue;
    }

    final caminho = Path()..moveTo(traco.first.dx, traco.first.dy);

    for (final ponto in traco.skip(1)) {
      caminho.lineTo(ponto.dx, ponto.dy);
    }

    canvas.drawPath(caminho, tinta);
  }
}

class _AssinaturaPainter extends CustomPainter {
  final List<List<Offset>> tracos;

  const _AssinaturaPainter(this.tracos);

  @override
  void paint(Canvas canvas, Size size) => _desenharTracos(canvas, tracos);

  // A lista é alterada no lugar; sempre redesenha.
  @override
  bool shouldRepaint(covariant _AssinaturaPainter oldDelegate) => true;
}
