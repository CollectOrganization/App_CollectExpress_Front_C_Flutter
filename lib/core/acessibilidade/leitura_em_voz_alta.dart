import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lê um texto em voz alta. A interface permite trocar o leitor nos testes.
abstract class LeitorEmVozAlta {
  Future<void> ler(String texto);
  Future<void> parar();
}

/// Usa a síntese de voz do aparelho (Android) ou do navegador (Web).
class LeitorFlutterTts implements LeitorEmVozAlta {
  LeitorFlutterTts() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _parado = false;

  @override
  Future<void> ler(String texto) async {
    _parado = false;
    await _tts.setLanguage('pt-BR');
    await _tts.awaitSpeakCompletion(true);
    for (final trecho in dividirEmTrechos(texto)) {
      if (_parado) break;
      await _tts.speak(trecho);
    }
  }

  @override
  Future<void> parar() async {
    _parado = true;
    await _tts.stop();
  }
}

final leitorEmVozAltaProvider = Provider<LeitorEmVozAlta>(
  (ref) => LeitorFlutterTts(),
);

/// `true` enquanto a tela está sendo lida.
class LeituraNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> ler(String texto) async {
    if (texto.trim().isEmpty) return;
    state = true;
    try {
      await ref.read(leitorEmVozAltaProvider).ler(texto);
    } finally {
      state = false;
    }
  }

  Future<void> parar() async {
    await ref.read(leitorEmVozAltaProvider).parar();
    state = false;
  }
}

final leituraProvider = NotifierProvider<LeituraNotifier, bool>(
  LeituraNotifier.new,
);

/// O Android aceita até 4.000 caracteres por fala; acima disso, o texto
/// é dividido nas quebras de linha.
List<String> dividirEmTrechos(String texto, {int limite = 3000}) {
  final trechos = <String>[];
  final atual = StringBuffer();
  for (final linha in texto.split('\n')) {
    var resto = linha.trim();
    while (resto.length > limite) {
      trechos.add(resto.substring(0, limite));
      resto = resto.substring(limite);
    }
    if (atual.length + resto.length + 1 > limite && atual.isNotEmpty) {
      trechos.add(atual.toString());
      atual.clear();
    }
    if (resto.isNotEmpty) {
      if (atual.isNotEmpty) atual.write('\n');
      atual.write(resto);
    }
  }
  if (atual.isNotEmpty) trechos.add(atual.toString());
  return trechos;
}

/// Junta os textos visíveis da tela a partir de [contexto] (o Scaffold da
/// página), na ordem em que aparecem. Ignora o menu lateral e os ícones.
String textoDaTela(BuildContext contexto) {
  final partes = <String>[];
  // Ícones são desenhados como caracteres de uso privado da fonte.
  final usoPrivado = RegExp('[-]');

  void visitar(Element elemento) {
    final widget = elemento.widget;
    if (widget is Drawer || widget is Icon) return;
    if (widget is RichText) {
      final texto = widget.text.toPlainText().replaceAll(usoPrivado, '').trim();
      if (texto.isNotEmpty) partes.add(texto);
      return;
    }
    elemento.visitChildren(visitar);
  }

  (contexto as Element).visitChildren(visitar);
  return partes.join('\n');
}
