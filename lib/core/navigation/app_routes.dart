import '../models/enums.dart';

abstract final class AppRoutes {
  // Cliente/público
  static const home = '/';
  static const services = '/servicos';
  static const models = '/modelos';
  static const customerOrders = '/cliente/pedidos';
  static const cart = '/cliente/carrinho';
  static const customerProfile = '/cliente/perfil';
  static const trackOrder = '/cliente/acompanhar-pedido';

  // Autenticação
  static const login = '/login';

  /// Argumento do [login] quando ele é aberto no meio de uma ação (ex.:
  /// adicionar ao carrinho). Depois de entrar, o cliente volta para a tela
  /// que pediu o login, em vez de ir para o início. O login devolve `true`
  /// ao voltar.
  static const voltarAoEntrar = 'voltar-ao-entrar';

  static const register = '/cadastro';

  /// Recebe em `arguments` o e-mail já digitado no login, se houver.
  /// Ao terminar, devolve o e-mail para o login preencher.
  static const forgotPassword = '/esqueci-senha';
  static const about = '/saiba-mais';
  static const adminLogin = '/admin/login';
  static const adminRegister = '/admin/cadastro';

  // Fornecedor de caçambas
  static const supplierHome = '/fornecedor/inicio';
  static const supplierDumpsters = '/fornecedor/cacambas';
  static const supplierOrders = '/fornecedor/pedidos';
  static const supplierProfile = '/fornecedor/perfil';

  // Administrador geral
  static const adminHome = '/admin/inicio';
  static const adminUsers = '/admin/usuarios';
  static const adminPartners = '/admin/parceiros';
  static const adminFinance = '/admin/financas';
  static const adminSettings = '/admin/configuracoes';

  // Reciclagem
  static const recyclingMaterials = '/reciclagem/materiais';
  static const recyclingPartners = '/reciclagem/parceiros';
  static const recyclingCollections = '/reciclagem/coletas';

  /// Tela inicial de cada perfil: o painel do fornecedor, o do admin ou,
  /// para o cliente e para quem não entrou, a página inicial do app.
  ///
  /// Use em todo botão de "início" (menu, logo, depois do login) para que
  /// fornecedor e admin não caiam na área do cliente.
  static String inicioDoPerfil(TipoPerfil? perfil) {
    return switch (perfil) {
      TipoPerfil.cacambeiro => supplierHome,
      TipoPerfil.admin => adminHome,
      TipoPerfil.consumidor || null => home,
    };
  }
}
