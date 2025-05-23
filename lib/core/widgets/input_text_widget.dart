import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sacdia/core/constants.dart'; 

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final void Function(String?)? onChanged;
  final bool isNumber;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.onChanged,
    this.isNumber = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.inputFormatters,
  });

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define un radio constante para los bordes
    const double borderRadius = 12;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.labelText,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: sacBlack, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
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
              borderRadius: const BorderRadius.all(Radius.circular(borderRadius)),
            ),
            // El clipBehavior es importante para asegurar que el TextFormField respete el recorte del borde
            clipBehavior: Clip.antiAlias,
            child: TextFormField(
              controller: widget.controller,
              validator: widget.validator,
              obscureText: _obscureText,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters ?? (widget.isNumber
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null),
              maxLength: widget.maxLength,
              maxLengthEnforcement: widget.maxLengthEnforcement,
              autofocus: false,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: 'Escriba aquí...',
                // Utilizar bordes personalizados y transparentes para mantener el estilo consistente
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide.none,
                ),
                // Si hay maxLength, ocultar el contador
                counterText: widget.maxLength != null ? '' : null,
                // Aumentar el padding para que el texto no quede tan pegado a los bordes
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                hintStyle: const TextStyle(color: sacGrey),
                fillColor: Colors.white,
                filled: true,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: sacGrey)
                    : null,
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: sacBlack,
                        ),
                        onPressed: _toggleObscureText,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
