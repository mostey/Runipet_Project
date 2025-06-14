import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet_data.dart';
import '../models/exercise_data.dart';
import '../models/challenge_data.dart';
import '../models/shop_item.dart';
import '../models/friend_data.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';
  static String? _token;

  void updateToken(String token) {
    _token = token;
  }

  Map<String, String> _headers({bool jsonContent = false}) {
    final headers = <String, String>{};
    if (jsonContent) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<bool> checkEmail(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/check-email'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] == true;
    } else {
      throw Exception('이메일 중복 확인 실패');
    }
  }

  Future<bool> checkUsername(String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/check-username'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username}),
    );

    if (response.statusCode != 200) {
      throw Exception('아이디 중복 확인 실패');
    }

    final data = json.decode(response.body);
    if (data.containsKey('available')) {
      return data['available'] as bool;
    } else {
      throw Exception('응답 형식 오류');
    }
  }

  Future<void> sendVerificationCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-email/send'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? '인증 코드 전송 실패');
    }
    if (data['status'] == 'not_found') {
      throw Exception('존재하지 않는 이메일입니다.');
    }
  }

  Future<bool> confirmVerificationCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-email/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );
    return response.statusCode == 200;
  }

  Future<String> findUsername(String email, String nickname) async {
    final response = await http.post(
      Uri.parse('$baseUrl/find-id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'nickname': nickname}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['username'];
    } else {
      throw Exception('아이디 찾기 실패');
    }
  }

  Future<void> resetPassword(String username, String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('비밀번호 재설정 실패');
    }
  }

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    print("로그인 응답 코드: ${response.statusCode}");
    print("로그인 응답 본문: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      updateToken(data['access_token']);
    } else {
      throw Exception('로그인 실패: ${response.statusCode}');
    }
  }

  Future<void> register(String username, String password, String email, String nickname) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'email': email,
        'nickname': nickname,
      }),
    );
    if (response.statusCode != 201) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        final errorMessage = data['error'] ?? '회원가입 실패';
        throw Exception(errorMessage);
      } catch (_) {
        throw Exception('회원가입 실패 (응답 파싱 실패)');
      }
    }
  }

  Future<PetData> getPetData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/pet'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return PetData.fromJson(json.decode(response.body));
    } else {
      throw Exception('펫 정보 불러오기 실패');
    }
  }

  Future<void> updatePetData(PetData petData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/pet'),
      headers: _headers(jsonContent: true),
      body: json.encode(petData.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('펫 정보 업데이트 실패');
    }
  }

  Future<List<ExerciseData>> getExerciseHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/exercises'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExerciseData.fromJson(json)).toList();
    } else {
      throw Exception('운동 기록 불러오기 실패');
    }
  }

  Future<void> saveExercise(ExerciseData exercise) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: _headers(jsonContent: true),
      body: json.encode(exercise.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('운동 저장 실패');
    }
  }

  Future<List<ChallengeData>> getChallenges() async {
    final response = await http.get(
      Uri.parse('$baseUrl/challenges'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChallengeData.fromJson(json)).toList();
    } else {
      throw Exception('도전과제 불러오기 실패');
    }
  }

  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    final response = await http.put(
      Uri.parse('$baseUrl/challenges/$challengeId'),
      headers: _headers(jsonContent: true),
      body: json.encode({'progress': progress}),
    );
    if (response.statusCode != 200) {
      throw Exception('도전과제 진행도 업데이트 실패');
    }
  }

  Future<List<ShopItem>> getShopItems() async {
    final response = await http.get(
      Uri.parse('$baseUrl/shop-items'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ShopItem.fromJson(json)).toList();
    } else {
      throw Exception('상점 아이템 불러오기 실패');
    }
  }

  Future<void> purchaseItem(String itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shop/purchase'),
      headers: _headers(jsonContent: true),
      body: json.encode({'itemId': itemId}),
    );
    if (response.statusCode != 200) {
      throw Exception('아이템 구매 실패');
    }
  }

  Future<List<FriendData>> getFriends() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FriendData.fromJson(json)).toList();
    } else {
      throw Exception('친구 목록 불러오기 실패');
    }
  }

  Future<void> sendFriendRequest(String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/request'),
      headers: _headers(jsonContent: true),
      body: json.encode({'username': username}),
    );
    if (response.statusCode != 201) {
      throw Exception('친구 요청 실패');
    }
  }

  Future<void> acceptFriendRequest(String requesterId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/accept'),
      headers: _headers(jsonContent: true),
      body: json.encode({'requester_id': requesterId}),
    );
    if (response.statusCode != 200) {
      throw Exception('친구 요청 수락 실패');
    }
  }

  Future<void> deleteFriend(String friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/friends/remove?friend_id=$friendId'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('친구 삭제 실패');
    }
  }
}