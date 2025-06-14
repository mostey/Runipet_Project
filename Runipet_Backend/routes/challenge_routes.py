from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.challenge import Challenge
from extensions import db

challenge_bp = Blueprint("challenge", __name__)

# ✅ 사용자의 모든 챌린지 조회
@challenge_bp.route("/challenges", methods=["GET"])
@jwt_required()
def get_challenges():
    user_id = get_jwt_identity()
    challenges = Challenge.query.filter_by(user_id=user_id).all()
    result = [{
        "id": c.id,
        "title": c.title,
        "description": c.description,
        "progress": c.progress,
        "goal": c.goal,
        "completed": c.completed
    } for c in challenges]
    return jsonify(result), 200

# ✅ 챌린지 추가(생성)
@challenge_bp.route("/challenges", methods=["POST"])
@jwt_required()
def create_challenge():
    user_id = get_jwt_identity()
    data = request.get_json()
    title = data.get("title")
    goal = data.get("goal")

    if not title or goal is None:
        return jsonify({"error": "챌린지명과 목표값을 모두 입력해야 합니다."}), 400

    description = data.get("description", "")

    c = Challenge(
        user_id=user_id,
        title=title,
        description=description,
        goal=goal
    )
    db.session.add(c)
    db.session.commit()
    return jsonify({"message": "도전과제가 등록되었습니다."}), 201

# ✅ 챌린지 진행도/완료여부 갱신
@challenge_bp.route("/challenges/<int:challenge_id>", methods=["PUT"])
@jwt_required()
def update_challenge(challenge_id):
    user_id = get_jwt_identity()
    c = Challenge.query.filter_by(id=challenge_id, user_id=user_id).first()
    if not c:
        return jsonify({"error": "도전과제를 찾을 수 없습니다."}), 404
    data = request.get_json()
    c.progress = data.get("progress", c.progress)
    c.completed = data.get("completed", c.completed)
    db.session.commit()
    return jsonify({"message": "도전과제가 갱신되었습니다."}), 200