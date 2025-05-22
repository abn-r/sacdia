import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_bloc.dart';
import 'package:sacdia/core/catalogs/bloc/catalogs_event.dart' as catalog_events;
import 'package:sacdia/core/catalogs/bloc/catalogs_state.dart';
import 'package:sacdia/core/catalogs/models/country.dart';
import 'package:sacdia/core/catalogs/models/union.dart';
import 'package:sacdia/core/catalogs/models/local_field.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/core/widgets/selector_data_widget.dart';
import 'package:sacdia/features/post_register/bloc/post_register_bloc.dart';
import 'package:sacdia/features/post_register/bloc/post_register_event.dart';
import 'package:sacdia/features/post_register/bloc/post_register_state.dart';
import 'package:sacdia/features/post_register/models/club_models.dart';
import 'package:sacdia/features/post_register/widgets/selection_modal.dart';

class ClubInfoStep extends StatefulWidget {
  const ClubInfoStep({super.key});

  @override
  State<ClubInfoStep> createState() => _ClubInfoStepState();
}

class _ClubInfoStepState extends State<ClubInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _didShowSuccessMessage = false;

  final _countryController = TextEditingController();
  final _unionController = TextEditingController();
  final _localFieldController = TextEditingController();
  final _clubController = TextEditingController();
  final _clubTypeController = TextEditingController();
  final _classController = TextEditingController();

  Country? selectedCountry;
  Union? selectedUnion;
  LocalField? selectedLocalField;
  Club? selectedClub;
  ClubType? selectedClubType;
  Class? selectedClass;

  bool canSelectUnion = false;
  bool canSelectLocalField = false;
  bool canSelectClub = false;
  bool canSelectClubType = false;
  bool canSelectClass = false;
  bool isClubInfoComplete = false;

  List<Country> countries = [];
  List<Union> unions = [];
  List<LocalField> localFields = [];
  List<Club> clubs = [];
  List<ClubType> clubTypes = [];
  List<Class> classes = [];

  final Set<String> _notifiedAutoSelections = {};

  @override
  void initState() {
    super.initState();
    
    // Asegurar que se muestre desde el inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      
      // Solicitar carga de países al iniciar
      context.read<PostRegisterBloc>().add(const LoadCountriesRequested());
      
      // Asegurarnos de que la bandera de mensaje esté limpia al iniciar
      _didShowSuccessMessage = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _countryController.dispose();
    _unionController.dispose();
    _localFieldController.dispose();
    _clubController.dispose();
    _clubTypeController.dispose();
    _classController.dispose();
    super.dispose();
  }

  void _resetSuccessMessageFlag() {
    if (_didShowSuccessMessage) {
      setState(() {
        _didShowSuccessMessage = false;
      });
    }
  }

  void _showCountrySelectionModal() {
    _resetSuccessMessageFlag();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<CatalogsBloc, CatalogsState>(
        builder: (context, state) {
          if (state is CatalogsLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (state is CatalogsError) {
            return Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${state.message}',
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

          if (state is CatalogsLoaded) {
            return SelectionModal(
              title: 'Seleccionar País',
              subtitle: 'Elige el país en el que te encuentras',
              items: state.countries,
              selectedItems: selectedCountry != null ? [selectedCountry!] : [],
              itemBuilder: (country) => Text((country as Country).name),
              onConfirm: (selected) {
                if (selected.isNotEmpty) {
                  final country = selected.first as Country;
                  
                  // Enviar selección al bloc
                  context.read<PostRegisterBloc>().add(CountrySelected(country));
                  
                  setState(() {
                    selectedCountry = country;
                    _countryController.text = selectedCountry!.name;

                    // Resetear selecciones dependientes
                    selectedUnion = null;
                    selectedLocalField = null;
                    selectedClub = null;
                    selectedClubType = null;
                    selectedClass = null;

                    _unionController.clear();
                    _localFieldController.clear();
                    _clubController.clear();
                    _clubTypeController.clear();
                    _classController.clear();

                    // Permitir seleccionar unión
                    canSelectUnion = true;
                    canSelectLocalField = false;
                    canSelectClub = false;
                    canSelectClubType = false;
                    canSelectClass = false;
                    isClubInfoComplete = false;

                    // Filtrar uniones para este país
                    unions = state.unions
                        .where((union) =>
                            union.countryId == selectedCountry!.countryId)
                        .toList();
                  });
                }
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showUnionSelectionModal() {
    if (!canSelectUnion) return;
    
    _resetSuccessMessageFlag();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<CatalogsBloc, CatalogsState>(
          builder: (context, state) {
            if (state is! CatalogsLoaded) {
              return const Center(child: CupertinoActivityIndicator());
            }
            
            return SelectionModal(
              title: 'Seleccionar Unión',
              subtitle: 'Elige la unión a la que perteneces',
              items: unions,
              selectedItems: selectedUnion != null ? [selectedUnion!] : [],
              itemBuilder: (union) => Text((union as Union).name),
              onConfirm: (selected) {
                if (selected.isNotEmpty) {
                  final union = selected.first as Union;
                  
                  // Enviar selección al bloc
                  context.read<PostRegisterBloc>().add(UnionSelected(union));
                  
                  setState(() {
                    selectedUnion = union;
                    _unionController.text = selectedUnion!.name;

                    // Resetear selecciones dependientes
                    selectedLocalField = null;
                    selectedClub = null;
                    selectedClubType = null;
                    selectedClass = null;

                    _localFieldController.clear();
                    _clubController.clear();
                    _clubTypeController.clear();
                    _classController.clear();

                    // Permitir seleccionar campo local
                    canSelectLocalField = true;
                    canSelectClub = false;
                    canSelectClubType = false;
                    canSelectClass = false;
                    isClubInfoComplete = false;

                    // Filtrar campos locales para esta unión
                    print('🔍 Filtrando campos locales para unionId: ${selectedUnion!.unionId}');
                    print('🧾 Total de campos locales disponibles: ${state.localFields.length}');
                    
                    if (state.localFields.isNotEmpty) {
                      print('📋 Primer campo local: ${state.localFields.first}');
                    }
                    
                    localFields = state.localFields
                        .where((field) {
                          final matches = field.unionId == selectedUnion!.unionId;
                          print('🔄 Campo local ${field.name} (unionId: ${field.unionId}) ¿coincide? $matches');
                          return matches;
                        })
                        .toList();
                    
                    print('🔢 Campos locales filtrados: ${localFields.length}');
                  });
                }
              },
            );
          }
        );
      },
    );
  }

  void _showLocalFieldSelectionModal() {
    if (!canSelectLocalField) return;
    
    _resetSuccessMessageFlag();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<CatalogsBloc, CatalogsState>(
          builder: (context, state) {
            if (state is! CatalogsLoaded) {
              return const Center(child: CupertinoActivityIndicator());
            }
            
            print('🏛️ Mostrando modal de campos locales');
            print('🔢 Campos locales disponibles para mostrar: ${localFields.length}');
            if (localFields.isEmpty && state.localFields.isNotEmpty) {
              // Intento de recuperación si por alguna razón los campos filtrados están vacíos
              print('⚠️ Lista localFields vacía pero state.localFields tiene ${state.localFields.length} elementos');
              print('🔄 Re-filtrando campos locales para unionId: ${selectedUnion?.unionId ?? "null"}');
              
              if (selectedUnion != null) {
                localFields = state.localFields
                    .where((field) => field.unionId == selectedUnion!.unionId)
                    .toList();
                print('🔄 Después de re-filtrar: ${localFields.length} campos locales');
              }
            }
            
            return SelectionModal(
              title: 'Seleccionar Campo Local',
              subtitle: 'Elige el campo local al que perteneces',
              items: localFields,
              selectedItems:
                  selectedLocalField != null ? [selectedLocalField!] : [],
              itemBuilder: (field) => Text((field as LocalField).name),
              onConfirm: (selected) {
                if (selected.isNotEmpty) {
                  final localField = selected.first as LocalField;
                  
                  // Enviar selección al bloc
                  context.read<PostRegisterBloc>().add(LocalFieldSelected(localField));
                  
                  setState(() {
                    selectedLocalField = localField;
                    _localFieldController.text = selectedLocalField!.name;

                    // Resetear selecciones dependientes
                    selectedClub = null;
                    selectedClubType = null;
                    selectedClass = null;

                    _clubController.clear();
                    _clubTypeController.clear();
                    _classController.clear();

                    // Permitir seleccionar club
                    canSelectClub = true;
                    canSelectClubType = false;
                    canSelectClass = false;
                    isClubInfoComplete = false;

                    // Cargar clubes del campo local seleccionado desde la API
                    context.read<CatalogsBloc>().add(
                          catalog_events.LoadClubsRequested(selectedLocalField!.localFieldId),
                        );
                  });
                }
              },
            );
          }
        );
      },
    );
  }

  void _showClubSelectionModal() {
    if (!canSelectClub) return;
    
    // Resetear flag de mensaje mostrado al iniciar una nueva selección
    _resetSuccessMessageFlag();
    
    // Asegurarnos de cargar los clubes antes de mostrar el modal
    if (selectedLocalField != null) {
      print('🔄 Cargando clubes para campo local: ${selectedLocalField!.name} (ID: ${selectedLocalField!.localFieldId})');
      context.read<CatalogsBloc>().add(
        catalog_events.LoadClubsRequested(selectedLocalField!.localFieldId),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<CatalogsBloc, CatalogsState>(
          builder: (context, state) {
            if (state is! CatalogsLoaded) {
              print('⚠️ Estado de catálogos no cargado');
              return const Center(child: CupertinoActivityIndicator());
            }
            
            final clubs = state.clubs.where(
              (club) => club.localFieldId == selectedLocalField!.localFieldId
            ).toList();
            
            print('📋 Clubes encontrados en modal: ${clubs.length}');
            if (clubs.isEmpty) {
              print('⚠️ No hay clubes para mostrar para el campo local: ${selectedLocalField!.localFieldId}');
            } else {
              print('✅ Clubes disponibles:');
              for (var club in clubs) {
                print('   - ${club.name} (ID: ${club.clubId})');
              }
            }
            
            return SelectionModal(
              title: 'Seleccionar Club',
              subtitle: clubs.isEmpty 
                ? 'No hay clubes disponibles para este campo local' 
                : 'Elige el club al que perteneces',
              items: clubs,
              selectedItems: selectedClub != null ? [selectedClub!] : [],
              itemBuilder: (club) => Text((club as Club).name),
              onConfirm: (selected) {
                if (selected.isNotEmpty) {
                  final club = selected.first as Club;
                  
                  // Enviar selección al bloc
                  context.read<PostRegisterBloc>().add(ClubSelected(club));
                  
                  setState(() {
                    selectedClub = club;
                    _clubController.text = selectedClub!.name;

                    // Resetear selecciones dependientes
                    selectedClubType = null;
                    selectedClass = null;

                    _clubTypeController.clear();
                    _classController.clear();

                    // Permitir seleccionar tipo de club
                    canSelectClubType = true;
                    canSelectClass = false;
                    isClubInfoComplete = false;
                    
                    // Si no tenemos tipos de club cargados, los solicitamos
                    if (state.clubTypes.isEmpty) {
                      context.read<CatalogsBloc>().add(catalog_events.LoadClubTypesRequested());
                    }
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  void _showClubTypeSelectionModal() {
    if (!canSelectClubType) return;
    
    // Resetear flag de mensaje mostrado al iniciar una nueva selección
    _resetSuccessMessageFlag();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<CatalogsBloc, CatalogsState>(
          builder: (context, state) {
            if (state is! CatalogsLoaded) {
              return const Center(child: CupertinoActivityIndicator());
            }
            
            return SelectionModal(
              title: 'Seleccionar Tipo de Club',
              subtitle: 'Elige el tipo de club que estás cursando',
              items: state.clubTypes,
              selectedItems: selectedClubType != null ? [selectedClubType!] : [],
              itemBuilder: (type) => Text((type as ClubType).name),
              onConfirm: (selected) {
                if (selected.isNotEmpty) {
                  final clubType = selected.first as ClubType;
                  
                  // Enviar selección al bloc
                  context.read<PostRegisterBloc>().add(ClubTypeSelected(clubType));
                  
                  setState(() {
                    selectedClubType = clubType;
                    _clubTypeController.text = selectedClubType!.name;

                    // Resetear clase
                    selectedClass = null;
                    _classController.clear();

                    // Permitir seleccionar clase
                    canSelectClass = true;
                    isClubInfoComplete = false;

                    // Cargar clases para este tipo de club
                    context.read<CatalogsBloc>().add(
                          catalog_events.LoadClassesRequested(selectedClubType!.clubTypeId),
                        );
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  void _showClassSelectionModal() {
    if (!canSelectClass) return;
    
    // Resetear flag de mensaje mostrado al iniciar una nueva selección
    _resetSuccessMessageFlag();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<CatalogsBloc, CatalogsState>(
          builder: (context, state) {
            if (state is! CatalogsLoaded) {
              return const Center(child: CupertinoActivityIndicator());
            }
            
            // Filtrar clases para el tipo de club seleccionado
            final availableClasses = state.classes.where((cls) {
              final matches = cls.clubTypeId == selectedClubType!.clubTypeId;
              return matches;
            }).toList();
                        
            if (availableClasses.isEmpty && state.classes.isNotEmpty) {
              
              return SelectionModal(
                title: 'Seleccionar Clase',
                subtitle: 'Elige la clase que estás cursando actualmente',
                items: state.classes,
                selectedItems: selectedClass != null ? [selectedClass!] : [],
                itemBuilder: (classItem) => Text((classItem as Class).name),
                onConfirm: (selected) {
                  if (selected.isNotEmpty) {
                    final selectedClassItem = selected.first as Class;
                    
                    // Enviar selección al bloc
                    context.read<PostRegisterBloc>().add(ClassSelected(selectedClassItem));
                    
                    setState(() {
                      selectedClass = selectedClassItem;
                      _classController.text = selectedClass!.name;
                      isClubInfoComplete = true;
                    });
                  }
                },
              );
            }
            
            return SelectionModal(
              title: 'Seleccionar Clase',
              subtitle: 'Elige la clase que estás cursando actualmente',
              items: availableClasses,
              selectedItems: selectedClass != null ? [selectedClass!] : [],
              itemBuilder: (classItem) => Text((classItem as Class).name),
              onConfirm: (selected) {
                if (selected.isNotEmpty) {
                  final selectedClassItem = selected.first as Class;
                  
                  // Enviar selección al bloc
                  context.read<PostRegisterBloc>().add(ClassSelected(selectedClassItem));
                  
                  setState(() {
                    selectedClass = selectedClassItem;
                    _classController.text = selectedClass!.name;
                    isClubInfoComplete = true;
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  void _saveClubInfo() {
    // Resetear flag de mensaje mostrado al guardar
    _resetSuccessMessageFlag();
    
    if (_formKey.currentState?.validate() ?? false) {
      if (isClubInfoComplete) {
        // Ya no es necesario enviar estos eventos aquí, ya que se envían en el momento de la selección
        context.read<PostRegisterBloc>().add(const SaveClubInfoRequested());
      }
    }
  }
  
  // Método para mostrar notificación de selección automática
  void _showAutoSelectNotification(BuildContext context, String entityType, String name) {
    final notificationKey = '${entityType}_$name';
    
    // Evitar mostrar la misma notificación más de una vez
    if (_notifiedAutoSelections.contains(notificationKey)) {
      return;
    }
    
    _notifiedAutoSelections.add(notificationKey);
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Se seleccionó automáticamente "$name" por ser el único $entityType disponible'),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Asegurar que el scroll esté en la posición inicial al construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    return BlocConsumer<PostRegisterBloc, PostRegisterState>(
      listenWhen: (previous, current) {
        // Escuchar cambios relevantes
        return previous.isLoading != current.isLoading ||
          previous.errorMessage != current.errorMessage ||
          previous.countries != current.countries ||
          previous.unions != current.unions ||
          previous.localFields != current.localFields ||
          previous.clubs != current.clubs ||
          previous.selectedCountry != current.selectedCountry ||
          previous.selectedUnion != current.selectedUnion ||
          previous.selectedLocalField != current.selectedLocalField ||
          previous.selectedClub != current.selectedClub ||
          previous.isClubInfoSaved != current.isClubInfoSaved ||
          previous.isPostRegisterCompleted != current.isPostRegisterCompleted ||
          previous.completePostRegisterError != current.completePostRegisterError;
      },
      listener: (context, PostRegisterState state) {
        // Actualizar estados locales según el estado del bloc
        setState(() {
          countries = state.countries;
          unions = state.unions;
          localFields = state.localFields;
          clubs = state.clubs;
          clubTypes = state.clubTypes;
          classes = state.classes;
          
          selectedCountry = state.selectedCountry;
          selectedUnion = state.selectedUnion;
          selectedLocalField = state.selectedLocalField;
          selectedClub = state.selectedClub;
          selectedClubType = state.selectedClubType;
          selectedClass = state.selectedClass;
          
          canSelectUnion = selectedCountry != null;
          canSelectLocalField = selectedUnion != null;
          canSelectClub = selectedLocalField != null;
          canSelectClubType = selectedClub != null;
          canSelectClass = selectedClubType != null;
          
          isClubInfoComplete = selectedCountry != null && 
                              selectedUnion != null && 
                              selectedLocalField != null && 
                              selectedClub != null &&
                              selectedClubType != null &&
                              selectedClass != null;
          
          // Actualizar los campos de texto
          if (selectedCountry != null) _countryController.text = selectedCountry!.name;
          if (selectedUnion != null) _unionController.text = selectedUnion!.name;
          if (selectedLocalField != null) _localFieldController.text = selectedLocalField!.name;
          if (selectedClub != null) _clubController.text = selectedClub!.name;
          if (selectedClubType != null) _clubTypeController.text = selectedClubType!.name;
          if (selectedClass != null) _classController.text = selectedClass!.name;
        });
        
        // Detectar y notificar selecciones automáticas
        // Para País
        if (state.countries.length == 1 && state.selectedCountry != null) {
          _showAutoSelectNotification(context, 'país', state.selectedCountry!.name);
        }
        
        // Para Unión
        if (state.unions.length == 1 && state.selectedUnion != null) {
          _showAutoSelectNotification(context, 'unión', state.selectedUnion!.name);
        }
        
        // Para Campo Local
        if (state.localFields.length == 1 && state.selectedLocalField != null) {
          _showAutoSelectNotification(context, 'campo local', state.selectedLocalField!.name);
        }
        
        // Para Club
        if (state.clubs.length == 1 && state.selectedClub != null) {
          _showAutoSelectNotification(context, 'club', state.selectedClub!.name);
        }
        
        // Mostrar mensaje de éxito SOLO cuando el estado isClubInfoSaved cambia a true
        if (state.isClubInfoSaved && !_didShowSuccessMessage && state.errorMessage == null) {
          _didShowSuccessMessage = true; // Marcar primero para evitar múltiples mensajes
          
          // Mostrar el SnackBar después de marcar la bandera
          _showSuccessSnackBar(context);
        }
        
        // Mostrar mensaje cuando el post-registro se haya completado exitosamente
        if (state.isPostRegisterCompleted) {
          _showSuccessSnackBar(context, 'Registro completado exitosamente. Ahora puedes acceder a todas las funciones de la aplicación.');
        }
        
        // Mostrar error si hubo problema al completar el post-registro
        if (state.completePostRegisterError != null) {
          _showErrorSnackBar(context, state.completePostRegisterError!);
        }
        
        // Mostrar errores o advertencias si existen
        if (state.errorMessage != null) {
          // Si el error es porque el usuario ya está registrado, mostrarlo como advertencia
          if (state.errorMessage!.contains('ya está registrado')) {
            _showWarningSnackBar(context, state.errorMessage!);
          } else {
            // Para otros errores, mostrar como error
            _showErrorSnackBar(context, state.errorMessage!);
          }
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'INFORMACIÓN DE CLUB',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: sacBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Selecciona de cada sección la información que corresponde a tus datospara continuar.',
                    style: TextStyle(
                      fontSize: 12,
                      color: sacBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: _showCountrySelectionModal,
                    child: CustomSelectorData(
                      labelText: '¿DE QUE PAÍS ERES?',
                      prefixIcon: Icons.language,
                      controller: _countryController,
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: canSelectUnion ? _showUnionSelectionModal : null,
                    child: Opacity(
                      opacity: canSelectUnion ? 1.0 : 0.5,
                      child: CustomSelectorData(
                        labelText: '¿A QUE UNIÓN PERTENECES?',
                        prefixIcon: Icons.business,
                        controller: _unionController,
                      ),
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: canSelectLocalField
                        ? _showLocalFieldSelectionModal
                        : null,
                    child: Opacity(
                      opacity: canSelectLocalField ? 1.0 : 0.5,
                      child: CustomSelectorData(
                        labelText: '¿A QUE CAMPO PERTENECES?',
                        prefixIcon: Icons.location_city,
                        controller: _localFieldController,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: canSelectClub ? _showClubSelectionModal : null,
                    child: Opacity(
                      opacity: canSelectClub ? 1.0 : 0.5,
                      child: CustomSelectorData(
                        labelText: '¿A QUE CLUB ASISTES?',
                        prefixIcon: Icons.groups,
                        controller: _clubController,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: canSelectClubType
                        ? _showClubTypeSelectionModal
                        : null,
                    child: Opacity(
                      opacity: canSelectClubType ? 1.0 : 0.5,
                      child: CustomSelectorData(
                        labelText: 'TIPO DE CLUB',
                        prefixIcon: Icons.category,
                        controller: _clubTypeController,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: canSelectClass ? _showClassSelectionModal : null,
                    child: Opacity(
                      opacity: canSelectClass ? 1.0 : 0.5,
                      child: CustomSelectorData(
                        labelText: '¿A QUE CLASE PERTENECES?',
                        prefixIcon: Icons.school,
                        controller: _classController,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: state.isLoading ||
                            !isClubInfoComplete ||
                            state.isClubInfoSaved
                        ? null
                        : _saveClubInfo,
                    child: state.isLoading
                        ? const CupertinoActivityIndicator(
                            color: sacRed,
                          )
                        : Text(
                            state.isClubInfoSaved ? 'Datos Guardados ✓' : 'Guardar Datos',
                            style: TextStyle(
                                color: state.isClubInfoSaved
                                    ? Colors.grey
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                  ),

                  if (state.isClubInfoSaved) ...[
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
                              'Información del club guardada correctamente. Ahora puedes continuar para tener acceso a las funciones de la aplicación.',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Método para mostrar un SnackBar de éxito
  void _showSuccessSnackBar(BuildContext context, [String? message]) {
    // Deshabilitar cualquier SnackBar que pudiera estar mostrándose actualmente
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Mostrar el nuevo SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Información guardada exitosamente'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  // Método para mostrar un SnackBar de advertencia
  void _showWarningSnackBar(BuildContext context, String message) {
    // Deshabilitar cualquier SnackBar que pudiera estar mostrándose actualmente
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Mostrar el nuevo SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  // Método para mostrar un SnackBar de error
  void _showErrorSnackBar(BuildContext context, String message) {
    // Deshabilitar cualquier SnackBar que pudiera estar mostrándose actualmente
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Mostrar el nuevo SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
