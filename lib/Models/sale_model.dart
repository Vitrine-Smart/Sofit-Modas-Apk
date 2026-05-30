// ============================================================
//  SOFIT MODAS — sale_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String codProduto;  
  final String nomeProduto;
  final String tam;         
  final int qtd;
  final double precoUnitario;
  final bool isItemAvulso;  

  SaleItem({
    required this.codProduto,
    required this.nomeProduto,
    required this.tam,
    required this.qtd,
    required this.precoUnitario,
    this.isItemAvulso = false,
  });

  double get subtotal => precoUnitario * qtd;

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    final cod = (map['codProduto'] ?? '').toString();
    return SaleItem(
      codProduto: cod,
      nomeProduto: (map['nomeProduto'] ?? '').toString(),
      tam: (map['tam'] ?? 'U').toString(),
      qtd: (map['qtd'] is int) ? map['qtd'] as int : (map['qtd'] as num).toInt(),
      precoUnitario: (map['precoUnitario'] is double) ? map['precoUnitario'] as double : (map['precoUnitario'] as num).toDouble(),
      isItemAvulso: cod.startsWith('VR_'),
    );
  }

  Map<String, dynamic> toMap() => {
        'codProduto': codProduto,
        'nomeProduto': nomeProduto,
        'tam': tam,
        'qtd': qtd,
        'precoUnitario': precoUnitario,
        'subtotal': subtotal,
        'isItemAvulso': isItemAvulso,
      };
}

enum TipoEntrega { retirada, entrega }

extension TipoEntregaExt on TipoEntrega {
  String get label => this == TipoEntrega.retirada ? 'Retirada' : 'Entrega';
}

class SaleModel {
  final String codVenda;         
  final List<SaleItem> itens;
  final double valorProdutos;    
  final double valorMaquininha;  
  final double valorFrete;       
  final TipoEntrega tipoEntrega;
  final String? enderecoEntrega; 
  final DateTime dataHora;
  final String origen;           
  final String? operador;        

  SaleModel({
    required this.codVenda,
    required this.itens,
    required this.valorProdutos,
    required this.valorMaquininha,
    required this.valorFrete,
    required this.tipoEntrega,
    this.enderecoEntrega,
    required this.dataHora,
    this.origen = 'mobile',
    this.operador,
  });

  double get diferenca => valorMaquininha - valorProdutos;
  double get totalPago => valorMaquininha + valorFrete;
  int get totalPecas => itens.fold(0, (s, i) => s + i.qtd);

  Map<String, dynamic> toFirestore() => {
        'codVenda': codVenda,
        'itens': itens.map((i) => i.toMap()).toList(),
        'valorProdutos': valorProdutos,
        'valorMaquininha': valorMaquininha,
        'diferenca': diferenca,
        'valorFrete': valorFrete,
        'totalPago': totalPago,
        'tipoEntrega': tipoEntrega.label,
        'enderecoEntrega': enderecoEntrega,
        'dataHora': Timestamp.fromDate(dataHora),
        'data': _formatarData(dataHora),
        'origem': origen,
        'operador': operador,
        'totalPecas': totalPecas,
      };

  factory SaleModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final rawItens = data['itens'];
    final itens = (rawItens is List)
        ? rawItens.whereType<Map<String, dynamic>>().map((i) => SaleItem.fromMap(i)).toList()
        : <SaleItem>[];

    DateTime dataHora;
    final rawData = data['dataHora'];
    if (rawData is Timestamp) {
      dataHora = rawData.toDate();
    } else if (rawData is String) {
      dataHora = DateTime.tryParse(rawData) ?? DateTime.now();
    } else {
      dataHora = DateTime.now();
    }

    final tipoStr = (data['tipoEntrega'] ?? 'Retirada').toString();
    final tipoEntrega = tipoStr == 'Entrega' ? TipoEntrega.entrega : TipoEntrega.retirada;

    double toDouble(dynamic v) => v == null ? 0.0 : (v is double ? v : (v as num).toDouble());

    return SaleModel(
      codVenda: docId,
      itens: itens,
      valorProdutos: toDouble(data['valorProdutos']),
      valorMaquininha: toDouble(data['valorMaquininha']),
      valorFrete: toDouble(data['valorFrete']),
      tipoEntrega: tipoEntrega,
      enderecoEntrega: data['enderecoEntrega'] as String?,
      dataHora: dataHora,
      origen: (data['origem'] ?? 'desktop').toString(),
      operador: data['operador'] as String?,
    );
  }
}

String _formatarData(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
