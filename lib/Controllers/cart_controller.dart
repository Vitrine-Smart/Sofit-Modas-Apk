// ============================================================
//  SOFIT MODAS — cart_controller.dart
// ============================================================

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../services/firebase_service.dart';

class CartController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  final List<SaleItem> _itens = [];
  double _valorMaquininhaManual = 0.0;
  bool _isValorMaquininhaEditado = false;
  
  double _valorFrete = 0.0;
  TipoEntrega _tipoEntrega = TipoEntrega.retirada;
  String _enderecoEntrega = '';
  
  bool _carregando = false;

  List<SaleItem> get itens => _itens;
  bool get carregando => _carregando;
  TipoEntrega get tipoEntrega => _tipoEntrega;
  double get valorFrete => _valorFrete;
  String get enderecoEntrega => _enderecoEntrega;

  // Calcula o valor somado bruto dos itens do carrinho
  double get valorProdutos => _itens.fold(0.0, (soma, item) => soma + item.subtotal);

  // Retorna o valor da maquininha: ou o manual digitado ou a soma automática dos produtos
  double get valorMaquininha {
    if (_isValorMaquininhaEditado) {
      return _valorMaquininhaManual;
    }
    return valorProdutos;
  }

  double get totalGeral => valorMaquininha + _valorFrete;

  // Adiciona produto físico do estoque
  void adicionarProduto(ProductModel produto, ProductVariation variacao, int qtd) {
    // Verifica se já existe esse produto com esse tamanho no carrinho
    final index = _itens.indexWhere((item) => item.codProduto == produto.cod && item.tam == variacao.tam);

    if (index != -1) {
      final itemAntigo = _itens[index];
      _itens[index] = SaleItem(
        codProduto: itemAntigo.codProduto,
        nomeProduto: itemAntigo.nomeProduto,
        tam: itemAntigo.tam,
        qtd: itemAntigo.qtd + qtd,
        precoUnitario: itemAntigo.precoUnitario,
      );
    } else {
      _itens.add(SaleItem(
        codProduto: produto.cod,
        nomeProduto: produto.nome,
        tam: variacao.tam,
        qtd: qtd,
        precoUnitario: produto.precoPromo ?? variacao.preco,
      ));
    }

    if (!_isValorMaquininhaEditado) _valorMaquininhaManual = valorProdutos;
    notifyListeners();
  }

  // Adiciona um valor customizado/avulso digitado na hora
  void adicionarItemAvulso(String nome, double valor) {
    final codAvulso = 'VR_${DateTime.now().millisecondsSinceEpoch}';
    _itens.add(SaleItem(
      codProduto: codAvulso,
      nomeProduto: nome,
      tam: 'U',
      qtd: 1,
      precoUnitario: valor,
      isItemAvulso: true,
    ));
    
    if (!_isValorMaquininhaEditado) _valorMaquininhaManual = valorProdutos;
    notifyListeners();
  }

  // Define um valor alterado customizado direto para passar na maquininha
  void setValorMaquininhaManual(double valor) {
    _valorMaquininhaManual = valor;
    _isValorMaquininhaEditado = true;
    notifyListeners();
  }

  void resetarValorMaquininha() {
    _isValorMaquininhaEditado = false;
    _valorMaquininhaManual = valorProdutos;
    notifyListeners();
  }

  void atualizarFrete(double valor, TipoEntrega tipo, {String endereco = ''}) {
    _valorFrete = tipo == TipoEntrega.entrega ? valor : 0.0;
    _tipoEntrega = tipo;
    _enderecoEntrega = endereco;
    notifyListeners();
  }

  void removerItem(int index) {
    _itens.removeAt(index);
    if (!_isValorMaquininhaEditado) _valorMaquininhaManual = valorProdutos;
    notifyListeners();
  }

  void limparCarrinho() {
    _itens.clear();
    _valorMaquininhaManual = 0.0;
    _isValorMaquininhaEditado = false;
    _valorFrete = 0.0;
    _tipoEntrega = TipoEntrega.retirada;
    _enderecoEntrega = '';
    _carregando = false;
    notifyListeners();
  }

  // Processa a venda final em Batch no Firebase
  Future<bool> checkout(String? operador) async {
    if (_itens.isEmpty) return false;

    _carregando = true;
    notifyListeners();

    try {
      final proximoCodigo = await _firebaseService.gerarProximoCodigoVenda();
      
      final venda = SaleModel(
        codVenda: proximoCodigo,
        itens: List.from(_itens),
        valorProdutos: valorProdutos,
        valorMaquininha: valorMaquininha,
        valorFrete: _valorFrete,
        tipoEntrega: _tipoEntrega,
        enderecoEntrega: _tipoEntrega == TipoEntrega.entrega ? _enderecoEntrega : null,
        dataHora: DateTime.now(),
        operador: operador,
      );

      await _firebaseService.finalizarVenda(venda);
      limparCarrinho();
      return true;
    } catch (e) {
      _carregando = false;
      notifyListeners();
      return false;
    }
  }
}
