import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../models/search_result_model.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<SearchResultModel>>> search(String query);
  Future<Either<Failure, List<String>>> getSearchHistory();
  Future<Either<Failure, bool>> addToSearchHistory(String query);
  Future<Either<Failure, bool>> clearSearchHistory();
}

class SearchRepositoryImpl implements SearchRepository {
  @override
  Future<Either<Failure, List<SearchResultModel>>> search(String query) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<String>>> getSearchHistory() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, bool>> addToSearchHistory(String query) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> clearSearchHistory() async {
    return const Right(true);
  }
}
