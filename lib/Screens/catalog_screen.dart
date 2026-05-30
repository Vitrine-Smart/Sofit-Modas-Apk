// ============================================================
//  SOFIT MODAS — catalog_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../controllers/cart_controller.dart';
import '../models/product_model.dart';
import 'cart_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sofit Modas — PDV Mobile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartController>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.itens.length.toString()),
                isLabelVisible: cart.itens.isNotEmpty,
                alignment: const Alignment(0.7, -0.5),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: firebaseService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os produtos do Firebase.'));
          }
          final produtos = snapshot.data ?? [];
          if (produtos.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado no banco.'));
          }

          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final prod = produtos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(prod.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Cód: ${prod.cod} | Estoque: ${prod.estoqueTotal} pçs'),
                  trailing: Text(
                    'R\$ ${prod.precoExibicao.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onTap: () => _abrirSelecaoTamanho(context, prod),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirItemAvulsoDialog(context),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Valor Avulso', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _abrirSelecaoTamanho(BuildContext context, ProductModel produto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(produto.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Selecione o Tamanho:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: produto.variacoes.length,
                  itemBuilder: (context, idx) {
                    final v = produto.variacoes[idx];
                    final semEstoque = v.qtd <= 0;

                    return ListTile(
                      title: Text('Tamanho: ${v.tam}'),
                      subtitle: Text('Disponível: ${v.qtd} unidades'),
                      trailing: Text(
                        'R\$ ${(produto.precoPromo ?? v.preco).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: semEstoque ? Colors.red : Colors.black80,
                        ),
                      ),
                      enabled: !semEstoque,
                      onTap: () {
                        context.read<CartController>().adicionarProduto(produto, v, 1);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${produto.nome} (${v.tam}) adicionado!'),
                            backgroundColor: Colors.teal,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirItemAvulsoDialog(BuildContext context) {
    final nomeController = TextEditingController(text: 'Item Avulso');
    final valorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lançar Valor Avulso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Identificação/Nome'),
            ),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(labelText: 'Valor R\$', hintText: '0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
              if (valor > 0) {
                context.read<CartController>().adicionarItemAvulso(nomeController.text, valor);
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
