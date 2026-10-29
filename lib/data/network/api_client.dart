abstract class ApiClient {
  Future<Map<String, dynamic>> get({required String endpoint, required Map<String, dynamic> queryParams});
}
