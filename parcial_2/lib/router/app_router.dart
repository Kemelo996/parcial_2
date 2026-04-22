import 'package:go_router/go_router.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/accidentes/accidentes_screen.dart';
import '../views/establecimientos/establecimientos_screen.dart';
import '../views/establecimientos/establecimiento_detalle_screen.dart';
import '../views/establecimientos/establecimiento_form_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/accidentes',
        name: 'accidentes',
        builder: (context, state) => const AccidentesScreen(),
      ),
      GoRoute(
        path: '/establecimientos',
        name: 'establecimientos',
        builder: (context, state) => const EstablecimientosScreen(),
      ),
      GoRoute(
        path: '/establecimientos/nuevo',
        name: 'establecimiento-crear',
        builder: (context, state) => const EstablecimientoFormScreen(),
      ),
      GoRoute(
        path: '/establecimientos/:id',
        name: 'establecimiento-detalle',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EstablecimientoDetalleScreen(id: id);
        },
      ),
      GoRoute(
        path: '/establecimientos/:id/editar',
        name: 'establecimiento-editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return EstablecimientoFormScreen(id: id, datosIniciales: extra);
        },
      ),
    ],
  );
}