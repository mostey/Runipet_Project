import '../services/api_service.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();

  bool _isUsernameAvailable = false;
  String _usernameMessage = '';
  String _passwordMessage = '';
  String _birthMessage = '';
  String _emailMessage = '';
  String _emailCodeMessage = '';

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _birthController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  void _checkUsername() async {
    String username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _usernameMessage = "아이디를 입력하세요.";
        _isUsernameAvailable = false;
      });
      return;
    }
    try {
      bool available = await _apiService.checkUsername(username);
      setState(() {
        _isUsernameAvailable = available;
        _usernameMessage = available ? "사용 가능한 아이디입니다." : "이미 사용 중인 아이디입니다.";
      });
    } catch (e) {
      setState(() {
        _usernameMessage = "아이디 중복 확인 실패";
      });
    }
  }

  void _validatePassword() {
    String pw = _passwordController.text;
    String pwConfirm = _passwordConfirmController.text;
    setState(() {
      if (pw.isEmpty || pwConfirm.isEmpty) {
        _passwordMessage = '';
      } else if (pw != pwConfirm) {
        _passwordMessage = "비밀번호가 일치하지 않습니다.";
      } else {
        _passwordMessage = "비밀번호가 일치합니다.";
      }
    });
  }

  void _validateBirth() {
    String birth = _birthController.text.trim();
    final RegExp birthReg = RegExp(r'^\d{6}$'); // YYMMDD 간단 체크
    setState(() {
      if (birth.isEmpty) {
        _birthMessage = '';
      } else if (birthReg.hasMatch(birth)) {
        _birthMessage = "정상 입력된 생년월일입니다.";
      } else {
        _birthMessage = "생년월일 형식이 올바르지 않습니다.";
      }
    });
  }

  void _sendEmailCode() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailMessage = "이메일을 입력하세요.";
      });
      return;
    }

    try {
      // 먼저 중복 확인
      bool available = await _apiService.checkEmail(email);
      if (!available) {
        setState(() {
          _emailMessage = "이미 사용 중인 이메일입니다.";
        });
        return;
      }

      await _apiService.sendVerificationCode(email);
      setState(() {
        _emailMessage = "인증 코드가 전송되었습니다.";
      });
    } catch (e) {
      setState(() {
        _emailMessage = "인증 코드 전송 실패";
      });
    }
  }

  void _confirmEmailCode() async {
  String email = _emailController.text.trim().toLowerCase();
  String code = _emailCodeController.text.trim();
  
  if (email.isEmpty || code.isEmpty) {
    setState(() {
      _emailCodeMessage = "이메일과 인증 코드를 입력하세요.";
    });
    return;
  }
  
  try {
    bool verified = await _apiService.confirmVerificationCode(email, code);
    setState(() {
      _emailCodeMessage = verified ? "인증 성공" : "인증 코드가 올바르지 않습니다.";
    });
  } catch (e) {
    setState(() {
      _emailCodeMessage = "인증 오류";
    });
  }
}

  void _register() async {
    if (_emailCodeMessage != "인증 성공") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이메일 인증을 완료해주세요.")),
      );
      return;
    }
    if (!_isUsernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("아이디 중복 확인을 해주세요.")),
      );
      return;
    }
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _apiService.register(
        _usernameController.text.trim(),
        _passwordController.text,
        _emailController.text.trim(),
        _nameController.text.trim(), // nickname으로 전달됨
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("회원가입 성공")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 30),

                        // 아이디, 중복확인 버튼, 메시지
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: '아이디',
                                  filled: true,
                                  fillColor: Color(0xFFF5F5F5),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _checkUsername,
                              child: Text('중복확인', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        if (_usernameMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _usernameMessage,
                              style: TextStyle(color: _isUsernameAvailable ? Colors.green : Colors.red),
                            ),
                          ),
                        SizedBox(height: 15),

                        // 비밀번호 입력 필드
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '비밀번호',
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => _validatePassword(),
                        ),
                        SizedBox(height: 15),

                        // 비밀번호 재입력 필드
                        TextFormField(
                          controller: _passwordConfirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '비밀번호 재입력',
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => _validatePassword(),
                        ),
                        if (_passwordMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _passwordMessage,
                              style: TextStyle(color: _passwordMessage == "비밀번호가 일치합니다." ? Colors.green : Colors.red),
                            ),
                          ),
                        SizedBox(height: 15),

                        // 이름 입력 필드
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: '이름',
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),

                        // 생년월일 입력 필드 + 유효성 메시지
                        TextFormField(
                          controller: _birthController,
                          decoration: InputDecoration(
                            hintText: '생년월일 (YYMMDD)',
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => _validateBirth(),
                        ),
                        if (_birthMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _birthMessage,
                              style: TextStyle(color: _birthMessage == "정상 입력된 생년월일입니다." ? Colors.green : Colors.red),
                            ),
                          ),
                        SizedBox(height: 15),

                        // 이메일 + 인증코드 발송 버튼 + 메시지
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: '이메일',
                                  filled: true,
                                  fillColor: Color(0xFFF5F5F5),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _sendEmailCode,
                              child: Text('인증코드 발송', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        if (_emailMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _emailMessage,
                              style: TextStyle(color: _emailMessage == "인증 코드가 전송되었습니다." ? Colors.green : Colors.red),
                            ),
                          ),
                        SizedBox(height: 15),

                        // 인증코드 입력 + 확인 버튼 + 메시지
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailCodeController,
                                decoration: InputDecoration(
                                  hintText: '인증코드 입력',
                                  filled: true,
                                  fillColor: Color(0xFFF5F5F5),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _confirmEmailCode,
                              child: Text('코드 확인', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        if (_emailCodeMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _emailCodeMessage,
                                style: TextStyle(
                                  color: _emailCodeMessage == "인증 성공" ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                        SizedBox(height: 30),

                        // 가입하기 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _register,
                            child: Text(
                              '가입하기',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}