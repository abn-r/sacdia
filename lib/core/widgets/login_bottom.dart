import 'package:flutter/material.dart';

class LoginBottom extends StatefulWidget {
  const LoginBottom({super.key});

  @override
  State<LoginBottom> createState() => _LoginBottomState();
}

_validateAndSubmit() async {}
class _LoginBottomState extends State<LoginBottom> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _validateAndSubmit(),
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 67, 167, 138),
          borderRadius: BorderRadius.all(Radius.circular(3.6)),
        ),
        child: Text(
          "INICIAR SESIÓN",
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
