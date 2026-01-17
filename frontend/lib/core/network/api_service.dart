import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:frontend/features/tenant/data/models/tenant_model.dart';
import 'package:frontend/features/rent/data/models/rent_payment_model.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/house/data/models/house_model.dart';

class ApiService {
  final String baseUrl;
  String? _token;

  ApiService({required this.baseUrl});

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth Methods
  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromMap(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to login: ${json.decode(response.body)['error']}',
      );
    }
  }

  Future<AuthResponse> register(
    String email,
    String password,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'name': name}),
    );
    if (response.statusCode == 201) {
      return AuthResponse.fromMap(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to register: ${json.decode(response.body)['error']}',
      );
    }
  }

  Future<AuthResponse> signInWithGoogle(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id_token': idToken}),
    );
    if (response.statusCode == 200) {
      return AuthResponse.fromMap(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to sign in with Google: ${json.decode(response.body)['error']}',
      );
    }
  }

  Future<UserModel> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return UserModel.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // House Methods
  Future<List<House>> getHouses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/houses/'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => House.fromMap(item)).toList();
    } else {
      throw Exception('Failed to load houses');
    }
  }

  Future<House> createHouse(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/houses/'),
      headers: _getHeaders(),
      body: json.encode({'name': name}),
    );
    if (response.statusCode == 201) {
      return House.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to create house');
    }
  }

  Future<Flat> createFlat(
    String houseId,
    String number,
    double basicRent,
    double gasBill,
    double utilityBill,
    double waterCharges,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/houses/flats'),
      headers: _getHeaders(),
      body: json.encode({
        'house_id': houseId,
        'number': number,
        'basic_rent': basicRent,
        'gas_bill': gasBill,
        'utility_bill': utilityBill,
        'water_charges': waterCharges,
      }),
    );
    if (response.statusCode == 201) {
      return Flat.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to create flat');
    }
  }

  // Existing Methods
  Future<List<Tenant>> getTenants() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tenants/'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Tenant.fromMap(item)).toList();
    } else {
      throw Exception('Failed to load tenants');
    }
  }

  Future<Tenant> createTenant({
    required String name,
    required String phone,
    required String houseId,
    required String flatId,
    required String nidNumber,
    required double advanceAmount,
    required DateTime joinDate,
    File? nidFront,
    File? nidBack,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/tenants/'),
    );
    request.headers.addAll(_getHeaders());
    request.headers.remove('Content-Type');

    request.fields['name'] = name;
    request.fields['phone'] = phone;
    request.fields['house_id'] = houseId;
    request.fields['flat_id'] = flatId;
    request.fields['nid_number'] = nidNumber;
    request.fields['advance_amount'] = advanceAmount.toString();
    request.fields['join_date'] = joinDate.toIso8601String();

    if (nidFront != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'nid_front',
          nidFront.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (nidBack != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'nid_back',
          nidBack.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Tenant.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to create tenant: ${response.body}');
    }
  }

  Future<Tenant> updateTenantStatus(String tenantId, bool isActive) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tenants/$tenantId/status'),
      headers: _getHeaders(),
      body: json.encode({'is_active': isActive}),
    );

    if (response.statusCode == 200) {
      return Tenant.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to update tenant status');
    }
  }

  Future<List<RentPayment>> getTenantRents(String tenantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tenants/$tenantId/rents'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => RentPayment.fromMap(item)).toList();
    } else {
      throw Exception('Failed to load rents');
    }
  }

  Future<RentPayment> createRent(RentPayment rent) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/rents/'),
      headers: _getHeaders(),
      body: rent.toJson(),
    );
    if (response.statusCode == 201) {
      return RentPayment.fromMap(json.decode(response.body));
    } else {
      throw Exception('Failed to create rent');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard?user_id=$userId'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }
}
