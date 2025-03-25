import 'package:flutter/material.dart';
 
class SelectionModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<dynamic> items;
  final List<dynamic> selectedItems;
  final Function(List<dynamic>) onConfirm;
  final Widget Function(dynamic)? itemBuilder;

  const SelectionModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedItems,
    required this.onConfirm,
    this.itemBuilder,
  });

  @override
  State<SelectionModal> createState() => _SelectionModalState();
}

class _SelectionModalState extends State<SelectionModal> {
  late List<dynamic> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = _selectedItems.contains(item);
                
                return CheckboxListTile(
                  value: isSelected,
                  title: widget.itemBuilder != null 
                      ? widget.itemBuilder!(item)
                      : Text(item.toString()),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedItems.contains(item)) {
                          _selectedItems.add(item);
                        }
                      } else {
                        _selectedItems.remove(item);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onConfirm(_selectedItems);
              Navigator.pop(context);
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
} 