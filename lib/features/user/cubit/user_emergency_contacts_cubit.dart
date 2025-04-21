import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sacdia/features/user/models/emergency_contact_model.dart';
import 'package:sacdia/features/user/services/user_service.dart';

// Estados
abstract class UserEmergencyContactsState extends Equatable {
  const UserEmergencyContactsState();
  
  @override
  List<Object?> get props => [];
}

class UserEmergencyContactsInitial extends UserEmergencyContactsState {}

class UserEmergencyContactsLoading extends UserEmergencyContactsState {}

class UserEmergencyContactsLoaded extends UserEmergencyContactsState {
  final List<EmergencyContact> contacts;
  final DateTime lastUpdated;
  
  const UserEmergencyContactsLoaded(this.contacts, {required this.lastUpdated});
  
  @override
  List<Object?> get props => [contacts, lastUpdated];
}

class UserEmergencyContactsError extends UserEmergencyContactsState {
  final String message;
  
  const UserEmergencyContactsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class RelationshipTypesLoading extends UserEmergencyContactsState {}

class RelationshipTypesLoaded extends UserEmergencyContactsState {
  final List<RelationshipType> relationshipTypes;
  final DateTime lastUpdated;
  
  const RelationshipTypesLoaded(this.relationshipTypes, {required this.lastUpdated});
  
  @override
  List<Object?> get props => [relationshipTypes, lastUpdated];
}

class RelationshipTypesError extends UserEmergencyContactsState {
  final String message;
  
  const RelationshipTypesError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ContactAdded extends UserEmergencyContactsState {
  final EmergencyContact contact;
  
  const ContactAdded(this.contact);
  
  @override
  List<Object?> get props => [contact];
}

class ContactDeleted extends UserEmergencyContactsState {
  final int contactId;
  
  const ContactDeleted(this.contactId);
  
  @override
  List<Object?> get props => [contactId];
}

class ContactOperationError extends UserEmergencyContactsState {
  final String message;
  final String operation;
  
  const ContactOperationError({required this.message, required this.operation});
  
  @override
  List<Object?> get props => [message, operation];
}

// Cubit
class UserEmergencyContactsCubit extends Cubit<UserEmergencyContactsState> {
  final UserService userService;
  List<EmergencyContact> _contacts = [];
  List<RelationshipType> _relationshipTypes = [];
  
  // Constantes para caché
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  DateTime? _lastContactsUpdate;
  DateTime? _lastRelationshipTypesUpdate;
  
  UserEmergencyContactsCubit({required this.userService})
      : super(UserEmergencyContactsInitial());
  
  Future<void> getEmergencyContacts({bool forceRefresh = false}) async {
    // Verificar si ya hay contactos cargados y si la caché todavía es válida
    if (!forceRefresh && 
        _contacts.isNotEmpty && 
        _lastContactsUpdate != null && 
        DateTime.now().difference(_lastContactsUpdate!) < _cacheValidityDuration) {
      // Devolver los contactos de la caché
      emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
      return;
    }
    
    try {
      // Solo emitir estado de carga si no tenemos datos en caché
      if (_contacts.isEmpty) {
        emit(UserEmergencyContactsLoading());
      }
      
      final contacts = await userService.getEmergencyContacts();
      _contacts = contacts;
      _lastContactsUpdate = DateTime.now();
      
      emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
    } catch (e) {
      emit(UserEmergencyContactsError('Error al cargar los contactos: ${e.toString()}'));
    }
  }
  
  Future<void> getRelationshipTypes({bool forceRefresh = false}) async {
    // Verificar si ya hay tipos de relación cargados y si la caché todavía es válida
    if (!forceRefresh && 
        _relationshipTypes.isNotEmpty && 
        _lastRelationshipTypesUpdate != null && 
        DateTime.now().difference(_lastRelationshipTypesUpdate!) < _cacheValidityDuration) {
      // Devolver los tipos de relación de la caché
      emit(RelationshipTypesLoaded(_relationshipTypes, lastUpdated: _lastRelationshipTypesUpdate!));
      return;
    }
    
    try {
      // Solo emitir estado de carga si no tenemos datos en caché
      if (_relationshipTypes.isEmpty) {
        emit(RelationshipTypesLoading());
      }
      
      final types = await userService.getRelationshipTypes();
      _relationshipTypes = types;
      _lastRelationshipTypesUpdate = DateTime.now();
      
      emit(RelationshipTypesLoaded(_relationshipTypes, lastUpdated: _lastRelationshipTypesUpdate!));
    } catch (e) {
      emit(RelationshipTypesError('Error al cargar los tipos de relación: ${e.toString()}'));
    }
  }
  
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    required int relationshipTypeId,
  }) async {
    try {
      // Guardar una copia de los contactos actuales antes de la operación
      final List<EmergencyContact> previousContacts = List.from(_contacts);
      final previousLastUpdated = _lastContactsUpdate;
      
      // Emitimos el estado de carga antes de realizar la operación
      emit(UserEmergencyContactsLoading());
      
      final newContact = await userService.addEmergencyContact(
        name: name,
        phone: phone,
        relationshipTypeId: relationshipTypeId,
      );

      if (newContact != null) {
        // Agregamos el nuevo contacto a la lista en memoria
        _contacts.add(newContact);
        _lastContactsUpdate = DateTime.now();
        
        // Emitimos el estado de contacto añadido
        emit(ContactAdded(newContact));
        
        // Emitimos el estado actualizado con todos los contactos
        emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
      } else {
        emit(ContactOperationError(
          message: 'No se pudo añadir el contacto',
          operation: 'add',
        ));
        
        // Restauramos el estado anterior con los contactos existentes
        _contacts = previousContacts;
        _lastContactsUpdate = previousLastUpdated;
        if (_contacts.isNotEmpty && _lastContactsUpdate != null) {
          emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
        }
      }
    } catch (e) {
      emit(ContactOperationError(
        message: 'Error al añadir el contacto: ${e.toString()}',
        operation: 'add',
      ));
      
      // Restauramos el estado anterior con los contactos existentes
      if (_contacts.isNotEmpty && _lastContactsUpdate != null) {
        emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
      }
    }
  }
  
  Future<void> deleteEmergencyContact(int contactId) async {
    try {
      // Guardar una copia de los contactos actuales antes de la operación
      final List<EmergencyContact> previousContacts = List.from(_contacts);
      final previousLastUpdated = _lastContactsUpdate;
      
      // Emitimos el estado de carga antes de realizar la operación
      emit(UserEmergencyContactsLoading());
      
      final success = await userService.deleteEmergencyContact(contactId);
      
      if (success) {
        // Eliminamos el contacto de la lista en memoria
        _contacts.removeWhere((contact) => contact.id == contactId);
        _lastContactsUpdate = DateTime.now();
        
        // Emitimos el estado de contacto eliminado
        emit(ContactDeleted(contactId));
        
        // Emitimos el estado actualizado con todos los contactos
        emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
      } else {
        emit(ContactOperationError(
          message: 'No se pudo eliminar el contacto',
          operation: 'delete',
        ));
        
        // Restauramos el estado anterior con los contactos existentes
        _contacts = previousContacts;
        _lastContactsUpdate = previousLastUpdated;
        if (_contacts.isNotEmpty && _lastContactsUpdate != null) {
          emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
        }
      }
    } catch (e) {
      emit(ContactOperationError(
        message: 'Error al eliminar el contacto: ${e.toString()}',
        operation: 'delete',
      ));
      
      // Restauramos el estado anterior con los contactos existentes
      if (_contacts.isNotEmpty && _lastContactsUpdate != null) {
        emit(UserEmergencyContactsLoaded(_contacts, lastUpdated: _lastContactsUpdate!));
      }
    }
  }
  
  String? getRelationshipName(int relationshipTypeId) {
    final type = _relationshipTypes.where((t) => t.id == relationshipTypeId).firstOrNull;
    return type?.name;
  }
} 