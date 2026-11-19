import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Botões formados só por ícone não têm texto para o leitor de tela ler.
/// Sem `tooltip` (ou `semanticLabel`), o TalkBack e o leitor da Web
/// anunciam apenas "botão", sem dizer o que ele faz.
void main() {
  test('todo IconButton do app tem tooltip ou semanticLabel', () {
    final semNome = <String>[];
    final arquivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final arquivo in arquivos) {
      final codigo = arquivo.readAsStringSync();
      // IconButton( e IconButton.filled( etc.; IconButton.styleFrom só define estilo.
      final inicio = RegExp(r'\bIconButton(\.(?!styleFrom)\w+)?\(');
      for (final m in inicio.allMatches(codigo)) {
        final chamada = _chamadaCompleta(codigo, m.end - 1);
        if (!RegExp(r'\b(tooltip|semanticLabel)\s*:').hasMatch(chamada)) {
          final linha = '\n'.allMatches(codigo.substring(0, m.start)).length + 1;
          semNome.add('${arquivo.path}:$linha');
        }
      }
    }

    expect(semNome, isEmpty, reason: 'IconButton sem nome acessível');
  });
}

/// Devolve o trecho entre o parêntese de abertura e o de fechamento.
String _chamadaCompleta(String codigo, int abre) {
  var nivel = 0;
  for (var i = abre; i < codigo.length; i++) {
    if (codigo[i] == '(') nivel++;
    if (codigo[i] == ')' && --nivel == 0) return codigo.substring(abre, i + 1);
  }
  return codigo.substring(abre);
}
