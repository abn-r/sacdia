import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sacdia/core/constants.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../../domain/models/app_feature.dart';
import '../widgets/feature_grid_item.dart';
import '../widgets/user_header.dart';
import '../widgets/emergency_contact_fab.dart';
import 'package:sacdia/features/auth/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEmergencyFabExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const LoadHomeRequested());
  }

  void _handleFeatureTap(BuildContext context, AppFeature feature) {
    context.read<HomeBloc>().add(NavigateToFeatureRequested(feature));
    Navigator.of(context).pushNamed(feature.route);
  }

  void _handleEmergencyContact() {
    // Implementar la lógica para mostrar los contactos de emergencia
    setState(() {
      _isEmergencyFabExpanded = !_isEmergencyFabExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: sacGreen,
          body: SafeArea(
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: UserHeader(
                        user: UserModel(
                          id: '',
                          email: '',
                          postRegisterComplete: false,
                        ),
                        photoUrl: null,
                        onProfileTap: () {
                          // TODO: Implementar navegación al perfil
                        },
                      ),
                    ),
                    if (state.status == HomeStatus.loading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: sacRed,
                            backgroundColor: Colors.white,
                            strokeWidth: 4,
                          ),
                        ),
                      )
                    else if (state.status == HomeStatus.error)
                      SliverFillRemaining(
                        child: Center(
                          child:
                              Text(state.errorMessage ?? 'Error desconocido'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, top: 8, bottom: 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1.2,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final feature = state.features[index];
                              return FeatureGridItem(
                                feature: feature,
                                onTap: () =>
                                    _handleFeatureTap(context, feature),
                                onLongPress: () {
                                  context.read<HomeBloc>().add(
                                        ToggleFeatureFavoriteRequested(
                                            feature.id),
                                      );
                                },
                                isEnabled: feature.canAccess(state.userRoles),
                              );
                            },
                            childCount: state.features.length,
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: EmergencyContactFab(
                    onPressed: _handleEmergencyContact,
                    isExpanded: _isEmergencyFabExpanded,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
