// ============================================================
//  SOFIT MODAS — product_model.dart
// ============================================================

class ProductVariation {
  final String tam;  
  int qtd;           
  final double preco;

  ProductVariation({
    required this.tam,
    required this.qtd,
    required this.preco,
  });

  factory ProductVariation.fromMap(Map<String, dynamic> map) {
    return ProductVariation(
      tam: (map['tam'] ?? '').toString(),
      qtd: (map['qtd'] is int) ? map['qtd'] as int : (map['qtd'] as num).toInt(),
      preco: (map['preco'] is double) ? map['preco'] as double : (map['preco'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tam': tam,
        'qtd': qtd,
        'preco': preco,
      };

  ProductVariation copyWithQtd(int novaQtd) => ProductVariation(
        tam: tam,
        qtd: novaQtd,
        preco: preco,
      );
}

class ProductModel {
  final String nome;
  final String cod;       
  final String categoria; 
  final double? precoPromo; 
  List<ProductVariation> variacoes;
  final String? docId;

  ProductModel({
    required this.nome,
    required this.cod,
    required this.categoria,
    this.precoPromo,
    required this.variacoes,
    this.docId,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    final rawVariacoes = data['variacoes'];
    List<ProductVariation> variacoes = [];

    if (rawVariacoes is List) {
      variacoes = rawVariacoes
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductVariation.fromMap(v))
          .toList();
    }

    double? precoPromo;
    final rawPromo = data['precoPromo'];
    if (rawPromo != null) {
      precoPromo = (rawPromo is double) ? rawPromo : (rawPromo as num).toDouble();
    }

    return ProductModel(
      docId: documentId,
      nome: (data['nome'] ?? '').toString(),
      cod: (data['cod'] ?? '').toString(),
      categoria: (data['categoria'] ?? 'Geral').toString(),
      precoPromo: precoPromo,
      variacoes: variacoes,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nome': nome,
        'cod': cod,
        'categoria': categoria,
        'precoPromo': precoPromo, 
        'variacoes': variacoes.map((v) => v.toMap()).toList(),
      };

  double get precoExibicao {
    if (precoPromo != null) return precoPromo!;
    if (variacoes.isEmpty) return 0.0;
    return variacoes.map((v) => v.preco).reduce((a, b) => a < b ? a : b);
  }

  int get estoqueTotal => variacoes.fold(0, (soma, v) => soma + v.qtd);
  bool get temEstoque => variacoes.any((v) => v.qtd > 0);

  ProductVariation? variacaoPorTam(String tam) {
    try {
      return variacoes.firstWhere((v) => v.tam.toLowerCase() == tam.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
