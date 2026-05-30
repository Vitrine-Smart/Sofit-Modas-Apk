// ============================================================
//  SOFIT MODAS — firebase_service.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escutar os produtos em tempo real (organizado por categoria)
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore.collection('produtos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Registra a venda e atualiza o estoque usando BATCH (Tudo ou Nada)
  Future<void> finalizarVenda(SaleModel venda) async {
    final WriteBatch batch = _firestore.batch();

    // 1. Referência da nova venda usando o código gerado como ID do documento
    final DocumentReference vendaRef = _firestore.collection('vendas').doc(venda.codVenda);
    batch.set(vendaRef, venda.toFirestore());

    // 2. Dar baixa no estoque de cada item (se não for item avulso)
    for (var item in venda.itens) {
      if (item.isItemAvulso) continue; // Pula se for código de valor avulso

      final DocumentReference produtoRef = _firestore.collection('produtos').doc(item.codProduto);
      
      // Busca o produto atualizado para garantir consistência de concorrência
      final DocumentSnapshot snapshot = await produtoRef.get();
      if (!snapshot.exists) continue;

      final productData = snapshot.data() as Map<String, dynamic>;
      final produto = ProductModel.fromFirestore(productData, snapshot.id);

      // Localiza a variação correta para subtrair a quantidade
      final varStr = item.tam.toLowerCase();
      for (var v in produto.variacoes) {
        if (v.tam.toLowerCase() == varStr) {
          v.qtd = (v.qtd - item.qtd).clamp(0, 999999); // Evita estoque negativo
        }
      }

      // Adiciona a atualização do produto no mesmo pacote (Batch)
      batch.update(produtoRef, {
        'variacoes': produto.variacoes.map((v) => v.toMap()).toList(),
      });
    }

    // Executa tudo de uma vez de forma segura e atômica
    await batch.commit();
  }

  // Auxiliar para gerar o próximo código sequencial de venda de forma simples
  Future<String> gerarProximoCodigoVenda() async {
    try {
      final query = await _firestore
          .collection('vendas')
          .orderBy('dataHora', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return 'V0001';
      }

      final ultimoId = query.docs.first.id;
      if (ultimoId.startsWith('V')) {
        final numeroStr = ultimoId.substring(1);
        final numero = int.tryParse(numeroStr) ?? 0;
        final proximo = numero + 1;
        return 'V${proximo.toString().padLeft(4, '0')}';
      }
      
      return 'V${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return 'V${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
