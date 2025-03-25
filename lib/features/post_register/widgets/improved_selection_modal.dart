import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';

class ImprovedSelectionModal<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<T> items;
  final List<T> selectedItems;
  final Function(List<T>) onConfirm;
  final Widget Function(T) itemBuilder;
  final String Function(T) searchStringBuilder;
  final bool isLoading;

  const ImprovedSelectionModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedItems,
    required this.onConfirm,
    required this.itemBuilder,
    required this.searchStringBuilder,
    this.isLoading = false,
  });

  @override
  State<ImprovedSelectionModal<T>> createState() =>
      _ImprovedSelectionModalState<T>();
}

class _ImprovedSelectionModalState<T> extends State<ImprovedSelectionModal<T>> {
  late List<T> _selectedItems;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return widget.items;
    }
    return widget.items.where((item) {
      final searchString = widget.searchStringBuilder(item).toLowerCase();
      return searchString.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Empieza a mitad de pantalla
      minChildSize: 0.4, // Mínimo tamaño permitido
      maxChildSize: 0.95, // Casi pantalla completa
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              Expanded(
                child: widget.isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CupertinoActivityIndicator(
                              radius: 16,
                              color: sacRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cargando información...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/img/no-results.png',
                                  width: 70, height: 70),
                              SizedBox(height: 8),
                              Text(
                                'No se encontraron resultados',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final isSelected = _selectedItems.contains(item);

                              return CheckboxListTile(
                                value: isSelected,
                                title: widget.itemBuilder(item),
                                activeColor: sacRed,
                                checkColor: Colors.white,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if ((item is Disease &&
                                              (item as Disease).diseaseId ==
                                                  0) ||
                                          (item is Allergy &&
                                              (item as Allergy).allergyId ==
                                                  0)) {
                                        _selectedItems.clear();
                                        _selectedItems.add(item);
                                      } else {
                                        // Remover "Ninguna" si se selecciona otro elemento
                                        _selectedItems.removeWhere((i) =>
                                            (i is Disease &&
                                                (i as Disease).diseaseId ==
                                                    0) ||
                                            (i is Allergy &&
                                                (i as Allergy).allergyId == 0));

                                        if (!_selectedItems.contains(item)) {
                                          _selectedItems.add(item);
                                        }
                                      }
                                    } else {
                                      _selectedItems.removeWhere((i) =>
                                          i == item ||
                                          (i is Disease &&
                                              item is Disease &&
                                              (i as Disease).diseaseId ==
                                                  (item as Disease)
                                                      .diseaseId) ||
                                          (i is Allergy &&
                                              item is Allergy &&
                                              (i as Allergy).allergyId ==
                                                  (item as Allergy).allergyId));
                                    }
                                  });
                                },
                              );
                            },
                          ),
              ),

              // Botones de acción
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                            fontSize: 16,
                            color: sacBlack,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onConfirm(_selectedItems);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: sacRed,
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
