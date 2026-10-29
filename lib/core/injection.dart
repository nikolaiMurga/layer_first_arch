import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/db_client.dart';
import '../data/db/shared_db_client_impl.dart';
import '../data/mappers/currency_mapper.dart';
import '../data/network/api_client.dart';
import '../data/network/api_client_dio_impl.dart';
import '../data/network/api_client_http_impl.dart';
import '../data/network/endpoints.dart';
import '../data/network/params.dart';
import '../data/repos/local_repo_impl.dart';
import '../data/repos/network_repo_impl.dart';
import '../domain/repos/local_repo.dart';
import '../domain/repos/network_repo.dart';
import '../domain/use_cases/currency_use_case.dart';
import '../domain/use_cases/favorites_use_case.dart';
import '../presentation/favorites/bloc/favorites_cubit.dart';
import '../presentation/home/bloc/home_cubit.dart';
import '../resources/app_constants.dart';
import '../resources/app_strings.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  final Params params = Params();
  // api clients
  getIt.registerSingleton<Dio>(Dio(BaseOptions(
    baseUrl: Endpoints.baseUrl,
    headers: params.getHeaders(token: dotenv.env[AppStrings.apiToken]),
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    sendTimeout: AppConstants.sendTimeout,
  )));
  getIt.registerSingleton<ApiClient>(ApiClientDioImpl(getIt<Dio>()));
  getIt.registerSingleton<http.Client>(http.Client());
  getIt.registerSingleton<ApiClient>(ApiClientHttpImpl(getIt<http.Client>(), params));

  // local storage
  getIt.registerSingletonAsync<SharedPreferences>(() async => await SharedPreferences.getInstance());
  await getIt.allReady();
  getIt.registerSingleton<DbClient>(SharedDbClientImpl(getIt<SharedPreferences>()));
  // getIt.registerSingleton<DbClient>(HiveDbClientImpl());

  // mappers
  getIt.registerFactory<CurrencyMapper>(() => CurrencyMapper());

  // repos
  getIt.registerFactory<NetworkRepo>(() => NetworkRepoImpl(getIt.get<ApiClient>(), getIt<CurrencyMapper>(), params));
  getIt.registerFactory<LocalRepo>(() => LocalRepoImpl(getIt<DbClient>(), getIt<CurrencyMapper>()));

  // use cases
  getIt.registerFactory<CurrencyUseCase>(() => CurrencyUseCase(getIt<NetworkRepo>()));
  getIt.registerSingleton<FavoritesUseCase>(FavoritesUseCase(getIt<LocalRepo>()));

  // blocs
  getIt.registerSingleton<HomeCubit>(HomeCubit(getIt<CurrencyUseCase>()));
  getIt.registerSingleton<FavoritesCubit>(FavoritesCubit(getIt<FavoritesUseCase>()));
}
