import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/core/widgets/input_text_widget.dart';
import 'package:sacdia/features/user/cubit/user_emergency_contacts_cubit.dart';
import 'package:sacdia/features/user/models/emergency_contact_model.dart';

class EmergencyContactModal extends StatefulWidget {
  final Function(String name, String phone, int relationshipTypeId) onConfirm;
  final EmergencyContact? contact; // Para edición

  const EmergencyContactModal({
    super.key,
    required this.onConfirm,
    this.contact,
  });

  @override
  State<EmergencyContactModal> createState() => _EmergencyContactModalState();
}

class _EmergencyContactModalState extends State<EmergencyContactModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _selectedRelationshipTypeId;

  @override
  void initState() {
    super.initState();

    // Cargar los tipos de relación al iniciar
    context.read<UserEmergencyContactsCubit>().getRelationshipTypes();

    // Si estamos editando, llenar los campos con los datos del contacto
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phone;
      _selectedRelationshipTypeId = widget.contact!.relationshipTypeId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserEmergencyContactsCubit, UserEmergencyContactsState>(
      builder: (context, state) {
        final bool isRelationshipLoading = state is RelationshipTypesLoading;
        final bool hasRelationshipError = state is RelationshipTypesError;
        final List<RelationshipType> relationshipTypes =
            state is RelationshipTypesLoaded ? state.relationshipTypes : [];

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.contact == null
                          ? 'CONTACTO DE EMERGENCIA'
                          : 'EDITAR CONTACTO',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: sacBlack, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Agrega la información de tu contacto para que tus directivos del club puedan contactarlo en caso de emergencia.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'NOMBRE COMPLETO',
                      keyboardType: TextInputType.name,
                      prefixIcon: Icons.person_outline,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'TELÉFONO',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      isNumber: true,
                      maxLength: 10,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) => value?.length != 10
                          ? 'El teléfono debe tener 10 dígitos'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Muestra el estado de carga de tipos de relación
                    if (isRelationshipLoading && relationshipTypes.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: sacRed),
                            SizedBox(height: 8),
                            Text('Cargando tipos de relación...'),
                          ],
                        ),
                      )
                    else if (hasRelationshipError && relationshipTypes.isEmpty)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: sacRed,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error al obtener tipos de relación.',
                              style: TextStyle(
                                color: sacRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<UserEmergencyContactsCubit>()
                                    .getRelationshipTypes(forceRefresh: true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sacRed,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(200, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Reintentar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (relationshipTypes.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'No se encontraron tipos de relación disponibles',
                              style: TextStyle(color: Colors.amber),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      // Selector de tipo de relación con estilo personalizado
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TIPO DE RELACIÓN',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: sacBlack,
                                      fontWeight: FontWeight.bold),
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
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
                              ),
                              child: DropdownButtonFormField<int>(
                                decoration: const InputDecoration(
                                  hintText: 'Seleccione el tipo de relación',
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  prefixIcon: Icon(Icons.people_outline,
                                      color: sacGrey),
                                ),
                                value: _selectedRelationshipTypeId,
                                hint: const Text(
                                    'Seleccione el tipo de relación',
                                    style: TextStyle(color: sacGrey)),
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: sacBlack),
                                isExpanded: true,
                                items: relationshipTypes.map((type) {
                                  return DropdownMenuItem<int>(
                                    value: type.id,
                                    child: Text(type.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRelationshipTypeId = value;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Seleccione el tipo de relación'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (isRelationshipLoading &&
                                  relationshipTypes.isEmpty) ||
                              relationshipTypes.isEmpty
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                widget.onConfirm(
                                    _nameController.text,
                                    _phoneController.text,
                                    _selectedRelationshipTypeId!);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sacRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is UserEmergencyContactsLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.contact == null ? 'Guardar' : 'Actualizar',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
