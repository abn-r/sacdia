import 'dart:ffi';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_bloc.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_event.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_state.dart';
import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/core/widgets/selector_data_widget.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/features/post_register/bloc/post_register_event.dart';
import 'package:sacdia/features/post_register/bloc/post_register_state.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';
import 'package:sacdia/features/post_register/widgets/allergies_selector_widget.dart';
import 'package:sacdia/features/post_register/widgets/disease_selector_widget.dart';
import 'package:sacdia/features/post_register/widgets/emergency_contact_modal.dart';
import 'package:sacdia/features/post_register/widgets/emergency_contacts_selector_widget.dart';
import 'package:sacdia/features/post_register/widgets/improved_selection_modal.dart';

class PersonalInfoStep extends StatefulWidget {
  const PersonalInfoStep({super.key});

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _baptismDateController = TextEditingController();
  final _bloodTypeController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _baptismDate;
  bool _isBaptized = false;
  String? _selectedGender;
  String? _selectedBloodType;
  double _maleOpacity = 0.5;
  double _femaleOpacity = 0.5;

  Country? selectedCountry;
  Union? selectedUnion;
  LocalField? selectedLocalField;

  @override
  void initState() {
    super.initState();

    // Comprobar si ya están cargados los catálogos antes de solicitarlos nuevamente
    final catalogsState = context.read<CatalogsBloc>().state;
    if (catalogsState is! CatalogsLoaded) {
      // Solo solicitamos catálogos si no están ya cargados
      context.read<CatalogsBloc>().add(LoadCatalogs());
    }

    // Cargar contactos de emergencia y tipos de relación
    context
        .read<PostRegisterBloc>()
        .add(const LoadEmergencyContactsRequested());
    context
        .read<PostRegisterBloc>()
        .add(const LoadRelationshipTypesRequested());
        
    // Obtener los valores del estado actual si existen
    final postRegisterState = context.read<PostRegisterBloc>().state;
    if (postRegisterState.bloodType != null) {
      setState(() {
        _selectedBloodType = postRegisterState.bloodType;
        _bloodTypeController.text = _selectedBloodType!;
      });
    }
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _baptismDateController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      locale: const Locale('es', 'MX'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isBirthDate) {
        final DateTime threeYearsAgo =
            DateTime.now().subtract(const Duration(days: 365 * 3));
        if (picked.isAfter(threeYearsAgo)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              content: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Debes ser mayor a 3 años',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              backgroundColor: sacRed,
            ),
          );
          return;
        }

        setState(() {
          _birthDate = picked;
          _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
          context.read<PostRegisterBloc>().add(
                BirthDateChanged(_birthDate!),
              );
        });
      } else {
        setState(() {
          _baptismDate = picked;
          _baptismDateController.text = DateFormat('yyyy-MM-dd').format(picked);
          context.read<PostRegisterBloc>().add(
                BaptismDateChanged(_baptismDate!),
              );
        });
      }
    }
  }

  void _toggleGender(String gender) {
    setState(() {
      _selectedGender = gender;
      if (gender == 'male') {
        _maleOpacity = 1.0;
        _femaleOpacity = 0.2;
        _selectedGender = 'Masculino';
      } else {
        _maleOpacity = 0.2;
        _femaleOpacity = 1.0;
        _selectedGender = 'Femenino';
      }
      context.read<PostRegisterBloc>().add(
            GenderChanged(gender, _selectedGender!),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostRegisterBloc, PostRegisterState>(
      listener: (context, state) {
        // Actualizar el campo de tipo de sangre si cambia en el estado
        if (state.bloodType != null && state.bloodType != _selectedBloodType) {
          setState(() {
            _selectedBloodType = state.bloodType;
            _bloodTypeController.text = _selectedBloodType!;
          });
        }
        
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Información actualizada correctamente'),
              backgroundColor: sacGreen,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        if (state.errorMessage != null &&
            !state.errorMessage!.contains('contacto') &&
            !state.errorMessage!.contains('relación')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Error al actualizar la información'),
                  Text(state.errorMessage!),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de género con imágenes
                  Column(
                    children: [
                      Text(
                        '¿ERES HOMBRE O MUJER?',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: sacBlack, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleGender('male'),
                            child: AnimatedOpacity(
                              opacity: _maleOpacity,
                              duration: const Duration(milliseconds: 400),
                              child: Image.asset(
                                'assets/img/boy.png',
                                width: 70,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleGender('female'),
                            child: AnimatedOpacity(
                              opacity: _femaleOpacity,
                              duration: const Duration(milliseconds: 400),
                              child: Image.asset(
                                'assets/img/girl.png',
                                width: 70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: CustomSelectorData(
                      labelText: '¿CUANDO ES TU CUMPLEAÑOS?',
                      prefixIcon: Icons.calendar_today,
                      controller: _birthDateController,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Column(
                    children: [
                      Text(
                        '¿ESTAS BAUTIZADO?',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: sacBlack, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment(
                            value: false,
                            label: Text('No', style: TextStyle(fontSize: 16)),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Si', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                        selected: {_isBaptized},
                        onSelectionChanged: (Set<bool> value) {
                          setState(() {
                            _isBaptized = value.first;
                            context
                                .read<PostRegisterBloc>()
                                .add(BaptismStatusChanged(_isBaptized));
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  if (_isBaptized)
                    GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: CustomSelectorData(
                        labelText: '¿CUANDO FUISTE BAUTIZADO?',
                        prefixIcon: Icons.calendar_today,
                        controller: _baptismDateController,
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Selector de tipo de sangre
                  GestureDetector(
                    onTap: () => _showBloodTypeModal(context),
                    child: CustomSelectorData(
                      labelText: '¿CUÁL ES TU TIPO DE SANGRE?',
                      prefixIcon: Icons.bloodtype,
                      controller: _bloodTypeController,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Envolvemos el widget en un BlocBuilder para asegurar que se actualice cuando cambie el estado
                  BlocBuilder<PostRegisterBloc, PostRegisterState>(
                    // Solo reconstruir cuando cambien los contactos o cuando termine de cargar
                    buildWhen: (previous, current) =>
                        previous.emergencyContacts !=
                            current.emergencyContacts ||
                        (previous.isLoading &&
                            !current.isLoading &&
                            current.emergencyContacts.isNotEmpty),
                    builder: (context, blocState) {
                      return EmergencyContactsSelectorWidget(
                        selectedContacts: blocState.emergencyContacts,
                        onTap: () => _showEmergencyContactsModal(context),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  DiseaseSelectorWidget(
                    selectedDiseases: state.userDiseases,
                    onTap: () => _showDiseasesModal(context),
                  ),
                  const SizedBox(height: 20),
                  AllergiesSelectorWidget(
                    selectedAllergies: state.userAllergies,
                    onTap: () => _showAllergiesModal(context),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state.isLoading || state.isPersonalInfoSaved
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              context
                                  .read<PostRegisterBloc>()
                                  .add(const SavePersonalInfoRequested());
                            }
                          },
                    child: state.isLoading
                        ? const CircularProgressIndicator(
                            color: sacRed,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(sacRed),
                          )
                        : Text(
                            state.isPersonalInfoSaved
                                ? 'Datos Guardados ✓'
                                : 'Guardar Datos',
                            style: TextStyle(
                                color: state.isPersonalInfoSaved
                                    ? Colors.grey
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                  ),
                  if (state.isPersonalInfoSaved) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Información guardada correctamente. Ahora puedes continuar al siguiente paso.',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEmergencyContactsModal(BuildContext context) {
    // Solo cargar tipos de relación si aún no están disponibles
    final state = context.read<PostRegisterBloc>().state;
    if (state.relationshipTypes.isEmpty && state.errorMessage == null) {
      context
          .read<PostRegisterBloc>()
          .add(const LoadRelationshipTypesRequested());
      print(
          'Solicitando tipos de relación para el modal de contactos de emergencia');
    } else if (state.errorMessage != null) {
      // Si hay un error pero tenemos tipos, limpiamos el mensaje
      if (state.relationshipTypes.isNotEmpty) {
        context
            .read<PostRegisterBloc>()
            .add(const ClearErrorMessagesRequested());
      }
    }

    // Guardar una referencia al BuildContext para usarlo de manera segura
    final BuildContext outerContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: EmergencyContactModal(
            onConfirm: (name, phone, relationship) {
              // Validar que los datos no sean nulos antes de proceder
              if (name.isEmpty || phone.isEmpty || relationship == null) {
                ScaffoldMessenger.of(modalContext).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa todos los campos'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Primero cierra el modal para evitar problemas de reconstrucción
              Navigator.of(modalContext).pop();

              try {
                // Usar el evento silencioso para evitar errores duplicados
                outerContext.read<PostRegisterBloc>().add(
                      AddEmergencyContactSilent(
                        name: name,
                        phone: phone,
                        relationshipTypeId: relationship,
                        onSuccess: (contact) {
                          // Recargar los contactos después de agregar uno nuevo
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (outerContext.mounted) {
                              outerContext
                                  .read<PostRegisterBloc>()
                                  .add(const LoadEmergencyContactsRequested());

                              // Mostrar mensaje de éxito
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline,
                                          color: Colors.white),
                                      SizedBox(width: 12),
                                      Text(
                                          'Contacto de emergencia agregado correctamente',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          });
                        },
                        onError: (error) {
                          if (outerContext.mounted) {
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error al agregar contacto: $error'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    );
              } catch (e) {
                print(
                    '❌ Error directo al intentar agregar contacto: ${e.toString()}');
                // Mostrar error solo si el contexto todavía está montado
                if (outerContext.mounted) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(
                      content: Text('Error inesperado: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  void _showDiseasesModal(BuildContext context) {
    context.read<PostRegisterBloc>().add(const LoadDiseasesRequested());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<PostRegisterBloc, PostRegisterState>(
        builder: (context, state) {
          if (state.errorMessage != null) {
            return Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${state.errorMessage}',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            );
          }

          List<Disease> allDiseases = [Disease(diseaseId: 0, name: 'Ninguna')];

          if (state.diseases.isNotEmpty) {
            allDiseases.addAll(state.diseases);
          }

          return ImprovedSelectionModal<Disease>(
            title: 'Seleccionar enfermedades',
            subtitle: 'Ayúdanos a saber las enfermedades que tienes.',
            items: allDiseases,
            selectedItems: state.userDiseases,
            itemBuilder: (disease) => Text(disease.name),
            searchStringBuilder: (disease) => disease.name,
            isLoading: state.isLoading,
            onConfirm: (selected) {
              context.read<PostRegisterBloc>().add(
                    DiseasesChanged(
                      List<Disease>.from(selected),
                    ),
                  );
            },
          );
        },
      ),
    );
  }

  void _showAllergiesModal(BuildContext context) {
    context.read<PostRegisterBloc>().add(const LoadAllergiesRequested());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<PostRegisterBloc, PostRegisterState>(
        builder: (context, state) {
          if (state.errorMessage != null) {
            return Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${state.errorMessage}',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            );
          }

          List<Allergy> allAllergies = [Allergy(allergyId: 0, name: 'Ninguna')];

          if (state.allergies.isNotEmpty) {
            allAllergies.addAll(state.allergies);
          }

          return ImprovedSelectionModal<Allergy>(
            title: 'Seleccionar alergias',
            subtitle: 'Ayúdanos a saber las alergias que tienes.',
            items: allAllergies,
            selectedItems: state.userAllergies,
            itemBuilder: (allergy) => Text(allergy.name),
            searchStringBuilder: (allergy) => allergy.name,
            isLoading: state.isLoading,
            onConfirm: (selected) {
              context.read<PostRegisterBloc>().add(
                    AllergiesChanged(
                      List<Allergy>.from(selected),
                    ),
                  );
            },
          );
        },
      ),
    );
  }

  void _showBloodTypeModal(BuildContext context) {
    final List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImprovedSelectionModal<String>(
        title: 'Seleccionar tipo de sangre',
        subtitle: 'Por favor, selecciona tu tipo de sangre.',
        items: bloodTypes,
        selectedItems: _selectedBloodType != null ? [_selectedBloodType!] : [],
        itemBuilder: (bloodType) => Text(bloodType),
        searchStringBuilder: (bloodType) => bloodType,
        onConfirm: (selected) {
          if (selected.isNotEmpty) {
            setState(() {
              _selectedBloodType = selected.first;
              _bloodTypeController.text = _selectedBloodType!;
            });
            
            // Enviar el evento al bloc para actualizar el estado
            context.read<PostRegisterBloc>().add(
              BloodTypeChanged(_selectedBloodType!),
            );
          }
        },
      ),
    );
  }

  // void _showBottomSheet(BuildContext context) {
  //   showCupertinoModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     barrierColor: CupertinoColors.black.withOpacity(0.5),
  //     elevation: 10,
  //     expand: false,
  //     topRadius: const Radius.circular(10),
  //     builder: (context) => Container(
  //       decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.only(
  //             topLeft: Radius.circular(10),
  //             topRight: Radius.circular(10),
  //           )),
  //       child: CupertinoPageScaffold(
  //         backgroundColor: Colors.white,
  //         navigationBar: CupertinoNavigationBar(
  //           backgroundColor: Colors.white,
  //           middle: const Text('Seleccione datos'),
  //           leading: CupertinoButton(
  //             padding: EdgeInsets.zero,
  //             child: const Text('Cerrar',
  //                 style:
  //                     TextStyle(color: sacBlack, fontWeight: FontWeight.bold)),
  //             onPressed: () => Navigator.of(context).pop(),
  //           ),
  //         ),
  //         child: SafeArea(
  //           bottom: false,
  //           child: ListView(
  //             controller: ModalScrollController.of(context),
  //             children: [
  //               const SizedBox(height: 16),
  //               CupertinoListSection(
  //                 backgroundColor: Colors.white,
  //                 children: [
  //                   CupertinoListTile(
  //                     title: const Text('Opción 1'),
  //                     trailing: const CupertinoListTileChevron(),
  //                     onTap: () {
  //                       // Acción para opción 1
  //                     },
  //                   ),
  //                   CupertinoListTile(
  //                     title: const Text('Opción 2'),
  //                     trailing: const CupertinoListTileChevron(),
  //                     onTap: () {
  //                       // Acción para opción 2
  //                     },
  //                   ),
  //                   CupertinoListTile(
  //                     title: const Text('Opción 3'),
  //                     subtitle: const Text('Opción 3 sub'),
  //                     trailing: const CupertinoListTileChevron(),
  //                     onTap: () {
  //                       // Acción para opción 3
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
