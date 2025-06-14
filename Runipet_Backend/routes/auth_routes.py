from flask import Blueprint, request, jsonify
from werkzeug.security import check_password_hash, generate_password_hash
from flask_jwt_extended import create_access_token
from models.user import User
from extensions import db
from datetime import timedelta
import random
import smtplib
from email.mime.text import MIMEText
import os

email_verification_codes = {}

auth_bp = Blueprint("auth", __name__)

# 로그인
@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "아이디와 비밀번호를 입력해주세요."}), 400

    user = User.query.filter_by(username=username).first()
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({"error": "아이디 또는 비밀번호가 올바르지 않습니다."}), 401

    access_token = create_access_token(identity=user.id, expires_delta=timedelta(hours=24))
    return jsonify({
        "access_token": access_token,
        "user_id": user.id,
        "username": user.username,
        "nickname": user.nickname,
        "profile_image": user.profile_image,
        "role": user.role,
        "coins": user.coins
    }), 200

# 회원가입
@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()

    username = data.get("username")
    password = data.get("password")
    email = data.get("email")
    nickname = data.get("nickname")

    if not username or not password or not email or not nickname:
        return jsonify({"error": "아이디, 비밀번호, 이메일, 닉네임은 필수입니다."}), 400

    if User.query.filter_by(username=username).first():
        print(f"[DEBUG] 이미 사용 중인 아이디: {username}")
        return jsonify({"error": "이미 사용 중인 아이디입니다."}), 409

    if User.query.filter_by(email=email).first():
        print(f"[DEBUG] 이미 사용 중인 이메일: {email}")
        return jsonify({"error": "이미 사용 중인 이메일입니다."}), 409

    hashed_password = generate_password_hash(password)

    new_user = User(
        username=username,
        password_hash=hashed_password,
        email=email,
        nickname=nickname
    )
    db.session.add(new_user)
    db.session.commit()

    return jsonify({
        "message": "회원가입이 완료되었습니다.",
        "user_id": new_user.id
    }), 201

# 이메일 중복 확인
@auth_bp.route("/check-email", methods=["POST"])
def check_email():
    data = request.get_json()
    email = data.get("email")

    if not email:
        return jsonify({"error": "이메일을 입력해주세요."}), 400

    user = User.query.filter_by(email=email).first()
    if user:
        return jsonify({"available": False, "message": "이미 사용 중인 이메일입니다."}), 200
    else:
        return jsonify({"available": True}), 200

# 이메일 인증 코드 전송
@auth_bp.route('/verify-email/send', methods=['POST'])
def send_verification_email():
    data = request.get_json()
    email = data.get('email')

    if not email:
        return jsonify({'error': '이메일을 입력해주세요.'}), 400

    code = str(random.randint(100000, 999999))
    email_verification_codes[email] = code

    email_user = os.getenv('EMAIL_USER')
    email_password = os.getenv('EMAIL_PASSWORD')

    msg = MIMEText(f"루니펫 이메일 인증코드: {code}")
    msg['Subject'] = 'Runipet 이메일 인증'
    msg['From'] = email_user
    msg['To'] = email

    try:
        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
            server.login(email_user, email_password)
            server.sendmail(email_user, [email], msg.as_string())
        return jsonify({'message': '인증 코드가 이메일로 전송되었습니다.'}), 200
    except Exception as e:
        return jsonify({'error': f'이메일 전송에 실패했습니다: {str(e)}'}), 500

# 이메일 인증 코드 확인
@auth_bp.route('/verify-email/confirm', methods=['POST'])
def confirm_verification_code():
    data = request.get_json()
    email = data.get('email', '').strip().lower()
    code = data.get('code', '').strip()

    print(f"[DEBUG] 요청된 인증 확인: {email} / {code}")    # 검토
    saved_code = email_verification_codes.get(email)
    print(f"[DEBUG] 저장된 코드: {saved_code}")             # 검토

    if not email or not code:
        return jsonify({'error': '이메일과 인증 코드를 모두 입력해주세요.'}), 400

    if saved_code and saved_code == code:
        return jsonify({'message': '이메일 인증에 성공하였습니다.'}), 200
    else:
        return jsonify({'error': '인증 코드가 올바르지 않거나 만료되었습니다.'}), 400

# 아이디 찾기
@auth_bp.route('/find-id', methods=['POST'])
def find_id():
    data = request.get_json()
    email = data.get('email')
    nickname = data.get('nickname')

    if not email or not nickname:
        return jsonify({'error': '이메일과 닉네임을 모두 입력해주세요.'}), 400

    user = User.query.filter_by(email=email, nickname=nickname).first()
    if not user:
        return jsonify({'error': '일치하는 사용자를 찾을 수 없습니다.'}), 404

    return jsonify({'username': user.username}), 200

# 비밀번호 재설정
@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    new_password = data.get('new_password')

    if not username or not email or not new_password:
        return jsonify({'error': '아이디, 이메일, 새 비밀번호를 모두 입력해주세요.'}), 400

    user = User.query.filter_by(username=username, email=email).first()
    if not user:
        return jsonify({'error': '입력하신 정보와 일치하는 계정을 찾을 수 없습니다.'}), 404

    user.password_hash = generate_password_hash(new_password)
    db.session.commit()

    return jsonify({'message': '비밀번호가 성공적으로 변경되었습니다.'}), 200

# 아이디 중복 확인
@auth_bp.route("/check-username", methods=["POST"])
def check_username():
    data = request.get_json()
    username = data.get("username")

    if not username:
        return jsonify({"error": "아이디를 입력해주세요."}), 400

    exists = User.query.filter_by(username=username).first() is not None
    return jsonify({"available": not exists}), 200