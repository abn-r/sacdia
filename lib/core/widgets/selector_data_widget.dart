import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';

class CustomSelectorData extends StatefulWidget {
  final String labelText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final void Function(String?)? onChanged;

  const CustomSelectorData({
    super.key,
    required this.labelText,
    this.prefixIcon,
    this.onChanged,
    this.controller,
  });

  @override
  CustomSelectorDataState createState() => CustomSelectorDataState();
}

class CustomSelectorDataState extends State<CustomSelectorData> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.labelText,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: sacBlack, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 4.2),
                  blurRadius: 38.4,
                ),
              ],
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: TextFormField(
              enabled: false,
              controller: widget.controller,
              autofocus: false,
              onChanged: widget.onChanged,
              style: const TextStyle(color: sacBlack),
              decoration: InputDecoration(
                hintText: 'Presione para seleccionar...',
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                hintStyle: const TextStyle(color: sacBlack),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: sacBlack)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
