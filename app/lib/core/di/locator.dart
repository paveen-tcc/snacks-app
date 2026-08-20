import 'dart:async';

import 'package:get_it/get_it.dart';
import '../auth/msal_service.dart';
import '../auth/microsoft_profile_photo_service.dart';
import '../network/api_client.dart';
import '../notifications/push_service.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/snack_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/sync/sync_engine.dart';
import '../../presentation/home/widgets/dispenser/can_3d_renderer.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // 0. MSAL
  final msalService = MsalService();
  await msalService.initialize();
  locator.registerSingleton<MsalService>(msalService);
  locator.registerLazySingleton<MicrosoftProfilePhotoService>(
    () => MicrosoftProfilePhotoService(
      acquireSession: msalService.acquireGraphSessionSilent,
    ),
  );

  // 1. Networking & Database
  locator.registerLazySingleton<ApiClient>(() => ApiClient());
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // 2. Repositories
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<SnackRepository>(
    () => SnackRepository(locator<ApiClient>(), locator<AppDatabase>()),
  );
  locator.registerLazySingleton<OrderRepository>(
    () => OrderRepository(locator<ApiClient>(), locator<AppDatabase>()),
  );
  locator.registerLazySingleton<AdminRepository>(
    () => AdminRepository(locator<ApiClient>()),
  );

  // Push notifications (order reminders). No-op until Firebase is configured.
  locator.registerLazySingleton<PushService>(
    () => PushService(locator<ApiClient>()),
  );
  locator<PushService>().attachListeners();

  // 3. Sync Engine
  locator.registerLazySingleton<SyncEngine>(
    () => SyncEngine(locator<ApiClient>(), locator<AppDatabase>()),
  );

  // Start the sync engine monitoring
  locator<SyncEngine>().start();

  // Warm the file-system cache for the drink-can 3D models as early as
  // possible so the first real WebView load (when the user opens Tins &
  // Cans) isn't also paying for a cold asset read. Fire-and-forget: this
  // must never block app startup, and a failure here is harmless.
  unawaited(precacheCan3DModels());
}
