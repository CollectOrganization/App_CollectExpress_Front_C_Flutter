import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../acessibilidade/acessibilidade.dart';
import '../acessibilidade/leitura_em_voz_alta.dart';

/// Opções de acessibilidade no menu lateral: tamanho do texto, alto
/// contraste e leitura da tela em voz alta.
class SecaoAcessibilidade extends ConsumerWidget {
  const SecaoAcessibilidade({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias = ref.watch(acessibilidadeProvider);
    final lendo = ref.watch(leituraProvider);
    final notifier = ref.read(acessibilidadeProvider.notifier);
    const estiloItem = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 18, 14, 6),
          child: Text(
            'ACESSIBILIDADE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            children: [
              const Expanded(
                child: Text('Tamanho do texto', style: estiloItem),
              ),
              IconButton(
                tooltip: 'Diminuir texto',
                onPressed: preferencias.podeDiminuir
                    ? notifier.diminuirTexto
                    : null,
                icon: const Icon(Icons.text_decrease),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${(preferencias.escalaTexto * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Aumentar texto',
                onPressed: preferencias.podeAumentar
                    ? notifier.aumentarTexto
                    : null,
                icon: const Icon(Icons.text_increase),
              ),
            ],
          ),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          title: const Text('Alto contraste', style: estiloItem),
          value: preferencias.altoContraste,
          onChanged: (_) => notifier.alternarContraste(),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Icon(
            lendo ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
            color: Colors.black,
          ),
          title: Text(
            lendo ? 'Parar leitura' : 'Ler a tela em voz alta',
            style: estiloItem,
          ),
          onTap: () {
            if (lendo) {
              ref.read(leituraProvider.notifier).parar();
            } else {
              _lerTela(context, ref);
            }
          },
        ),
      ],
    );
  }

  void _lerTela(BuildContext context, WidgetRef ref) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold == null) return;
    // Lê a página que está atrás do menu e fecha o menu.
    final texto = textoDaTela(scaffold.context);
    scaffold.closeEndDrawer();
    ref.read(leituraProvider.notifier).ler(texto);
  }
}
