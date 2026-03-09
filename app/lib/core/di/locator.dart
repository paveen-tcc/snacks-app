import 'package:get_it/get_it.dart';
import '../auth/msal_service.dart';
import '../network/api_client.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/snack_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/drink_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/sync/sync_engine.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // 0. MSAL
  final msalService = MsalService();
  await msalService.initialize();
  locator.registerSingleton<MsalService>(msalService);

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
  locator.registerLazySingleton<DrinkRepository>(
    () => DrinkRepository(locator<ApiClient>()),
  );
  locator.registerLazySingleton<AdminRepository>(
    () => AdminRepository(locator<ApiClient>()),
  );

  // 3. Sync Engine
  locator.registerLazySingleton<SyncEngine>(
    () => SyncEngine(locator<ApiClient>(), locator<AppDatabase>()),
  );

  // Start the sync engine monitoring
  locator<SyncEngine>().start();
}
