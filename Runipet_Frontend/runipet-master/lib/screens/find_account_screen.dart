import '../services/api_service.dart';
import 'package:flutter/material.dart';

class FindAccountScreen extends StatefulWidget {
  const FindAccountScreen({Key? key}) : super(key: key);

  @override
  _FindAccountScreenState createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 찾기'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '아이디 찾기'),
            Tab(text: '비밀번호 재설정'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FindIdForm(),
          ResetPasswordForm(),
        ],
      ),
    );
  }
}

class FindIdForm extends StatefulWidget {
  const FindIdForm({Key? key}) : super(key: key);

  @override
  _FindIdFormState createState() => _FindIdFormState();
}

class _FindIdFormState extends State<FindIdForm> {
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _foundUsername;
  final ApiService _apiService = ApiService();

  void _findUsername() async {
    try {
      final username = await _apiService.findUsername(
        _emailController.text,
        _nicknameController.text,
      );
      setState(() {
        _foundUsername = username;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 찾기에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: '이메일'),
          ),
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(labelText: '이름'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _findUsername,
            child: const Text('아이디 찾기'),
          ),
          const SizedBox(height: 20),
          if (_foundUsername != null)
            Text('아이디: $_foundUsername'),
        ],
      ),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({Key? key}) : super(key: key);

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _codeSent = false;

  void _sendCode() async {
    try {
      await _apiService.sendVerificationCode(_emailController.text);
      setState(() {
        _codeSent = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드 전송 실패')),
      );
    }
  }

  void _resetPassword() async {
    try {
      final verified = await _apiService.confirmVerificationCode(
        _emailController.text,
        _codeController.text,
      );

      if (!verified) {
        throw Exception('인증 실패');
      }

      await _apiService.resetPassword(
        _usernameController.text,
        _emailController.text,
        _newPasswordController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 재설정되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 재설정 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: '아이디'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: '이메일'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _sendCode,
            child: const Text('인증 코드 전송'),
          ),
          if (_codeSent) ...[
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: '인증 코드'),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _resetPassword,
              child: const Text('비밀번호 재설정'),
            ),
          ],
        ],
      ),
    );
  }
}