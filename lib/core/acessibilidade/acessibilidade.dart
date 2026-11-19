import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preferências de acessibilidade escolhidas no menu lateral.
class PreferenciasAcessibilidade {
  const PreferenciasAcessibilidade({
    this.escalaTexto = 1.0,
    this.altoContraste = false,
  });

  /// Multiplica o tamanho do texto definido no sistema (1.0 = 100%).
  final double escalaTexto;
  final bool altoContraste;

  static const escalaMinima = 0.8;
  static const escalaMaxima = 2.0;
  static const passo = 0.1;

  bool get podeAumentar => escalaTexto < escalaMaxima;
  bool get podeDiminuir => escalaTexto > escalaMinima;

  PreferenciasAcessibilidade copyWith({
    double? escalaTexto,
    bool? altoContraste,
  }) {
    return PreferenciasAcessibilidade(
      escalaTexto: escalaTexto ?? this.escalaTexto,
      altoContraste: altoContraste ?? this.altoContraste,
    );
  }
}

class AcessibilidadeNotifier extends Notifier<PreferenciasAcessibilidade> {
  @override
  PreferenciasAcessibilidade build() => const PreferenciasAcessibilidade();

  void aumentarTexto() => _mudarEscala(PreferenciasAcessibilidade.passo);

  void diminuirTexto() => _mudarEscala(-PreferenciasAcessibilidade.passo);

  void alternarContraste() {
    state = state.copyWith(altoContraste: !state.altoContraste);
  }

  void _mudarEscala(double delta) {
    // Arredonda para não acumular erro de ponto flutuante (1.1 + 0.1...).
    final nova = ((state.escalaTexto + delta) * 10).round() / 10;
    state = state.copyWith(
      escalaTexto: math.min(
        PreferenciasAcessibilidade.escalaMaxima,
        math.max(PreferenciasAcessibilidade.escalaMinima, nova),
      ),
    );
  }
}

final acessibilidadeProvider =
    NotifierProvider<AcessibilidadeNotifier, PreferenciasAcessibilidade>(
      AcessibilidadeNotifier.new,
    );

/// Aumenta o contraste em torno de um tom claro (230): o branco e o preto
/// continuam iguais, e as cores médias escurecem. O verde dos botões
/// (#49B453) vira #008200, que tem 5:1 com o texto branco (o mínimo das
/// WCAG para texto é 4,5:1); sem o filtro, ele tem 2,65:1.
const filtroAltoContraste = ColorFilter.matrix(<double>[
  2, 0, 0, 0, -230, //
  0, 2, 0, 0, -230, //
  0, 0, 2, 0, -230, //
  0, 0, 0, 1, 0, //
]);

const _filtroNeutro = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Aplica as preferências ao app inteiro. Fica no `builder` do MaterialApp.
///
/// O [ColorFiltered] está sempre na árvore (neutro quando o contraste está
/// desligado) para que ligar e desligar não reconstrua o Navigator e não
/// volte o usuário para a tela inicial.
class AcessibilidadeBuilder extends ConsumerWidget {
  const AcessibilidadeBuilder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias = ref.watch(acessibilidadeProvider);
    final mediaQuery = MediaQuery.of(context);
    final escalaDoSistema = mediaQuery.textScaler.scale(1);

    return ColorFiltered(
      colorFilter: preferencias.altoContraste
          ? filtroAltoContraste
          : _filtroNeutro,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(
            escalaDoSistema * preferencias.escalaTexto,
          ),
        ),
        child: child,
      ),
    );
  }
}
