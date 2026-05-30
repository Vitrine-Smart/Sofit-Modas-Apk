// ============================================================
//  SOFIT MODAS — cart_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cart_controller.dart';
import '../models/sale_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _maquininhaController = TextEditingController();
  final TextEditingController _freteController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _operadorController = TextEditingController(text: 'Mobile');

  @override
  void dispose() {
    _maquininhaController.dispose();
    _freteController.dispose();
    _enderecoController.dispose();
    _operadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    // Atualiza o campo de texto da maquininha se o usuário não estiver editando ele ativamente
    if (_maquininhaController.text.isEmpty && cart.valorMaquininha > 0) {
      _maquininhaController.text = cart.valorMaquininha.toStringAsFixed(2);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho / Finalizar Venda'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: cart.itens.isEmpty
          ? const Center(child: Text('Seu carrinho está vazio.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.itens.length,
                    itemBuilder: (context, index) {
                      final item = cart.itens[index];
                      return ListTile(
                        title: Text(item.nomeProduto),
                        subtitle: Text('Tam: ${item.tam} x ${item.qtd} un'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('R\$ ${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                context.read<CartController>().removerItem(index);
                                _maquininhaController.clear();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Bloco de Identificação
                        TextField(
                          controller: _operadorController,
                          decoration: const InputDecoration(labelText: 'Vendedor / Operador', isDense: true),
                        ),
                        const SizedBox(height: 10),

                        // Bloco de Valores Reais vs Maquininha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Soma Real dos Produtos:', style: TextStyle(fontSize: 14)),
                            Text('R\$ ${cart.valorProdutos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // CAMPO DE AJUSTE MANUAL DA MAQUININHA
                        TextField(
                          controller: _maquininhaController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Valor Digitado na Maquininha (R\$)',
                            hintText: cart.valorProdutos.toStringAsFixed(2),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.grey),
                              tooltip: 'Restaurar valor original',
                              onPressed: () {
                                context.read<CartController>().resetarValorMaquininha();
                                _maquininhaController.text = context.read<CartController>().valorProdutos.toStringAsFixed(2);
                              },
                            ),
                          ),
                          onChanged: (val) {
                            final valor = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            context.read<CartController>().setValorMaquininhaManual(valor);
                          },
                        ),
                        const SizedBox(height: 10),

                        // Bloco de Opções de Entrega / Retirada
                        Row(
                          children: [
                            const Text('Tipo: '),
                            ChoiceChip(
                              label: const Text('Retirada Loja'),
                              selected: cart.tipoEntrega == TipoEntrega.retirada,
                              onSelected: (_) {
                                cart.atualizarFrete(0, TipoEntrega.retirada);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Entrega/Motoboy'),
                              selected: cart.tipoEntrega == TipoEntrega.entrega,
                              onSelected: (_) {
                                final fVal = double.tryParse(_freteController.text.replaceAll(',', '.')) ?? 0.0;
                                cart.atualizarFrete(fVal, TipoEntrega.entrega, endereco: _enderecoController.text);
                              },
                            ),
                          ],
                        ),

                        if (cart.tipoEntrega == TipoEntrega.entrega) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _freteController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Valor Frete R\$'),
                                  onChanged: (val) {
                                    final fVal = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                                    cart.atualizarFrete(fVal, TipoEntrega.entrega, endereco: _enderecoController.text);
                                  },
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _enderecoController,
                            decoration: const InputDecoration(labelText: 'Endereço Completo de Entrega'),
                            onChanged: (val) {
                              cart.atualizarFrete(cart.valorFrete, TipoEntrega.entrega, endereco: val);
                            },
                          ),
                        ],
                        const Divider(height: 24),

                        // TOTAL FINAL COMBINADO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL GERAL (Com Frete):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('R\$ ${cart.totalGeral.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Botão que dispara o Checkout seguro
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            onPressed: cart.carregando
                                ? null
                                : () async {
                                    final sucesso = await context.read<CartController>().checkout(_operadorController.text);
                                    if (context.mounted) {
                                      if (sucesso) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Venda Gravada e Estoque Atualizado com Sucesso!'), backgroundColor: Colors.green),
                                        );
                                        Navigator.pop(context); // Volta pro catálogo
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Falha ao processar venda no Firebase.'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                            child: cart.carregando
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('CONCLUIR VENDA (BATCH)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
