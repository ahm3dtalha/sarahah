import uuid
from datetime import datetime, timezone
from pathlib import Path

import json
from app.schemas import LoginIn, MessageIn, RegisterIn

import bcrypt
from boto3.dynamodb.conditions import Key
from fastapi import Depends, FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles

from app.auth import create_token, current_user_id
from app.config import messages_table, users_table, queue_url, sqs


app = FastAPI(title="Sarahah")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/auth/register", status_code=201)
def register(data: RegisterIn):
    username = data.username.lower()
    email = data.email.lower()

    taken = users_table.query(
        IndexName="username-index",
        KeyConditionExpression=Key("username").eq(username),
    )["Items"]
    if taken:
        raise HTTPException(status_code=409, detail="اسم المستخدم محجوز")

    exists = users_table.query(
        IndexName="email-index",
        KeyConditionExpression=Key("email").eq(email),
    )["Items"]
    if exists:
        raise HTTPException(status_code=409, detail="البريد مسجّل مسبقًا")

    password_hash = bcrypt.hashpw(data.password.encode(), bcrypt.gensalt()).decode()
    user_id = str(uuid.uuid4())

    users_table.put_item(Item={
        "user_id": user_id,
        "username": username,
        "email": email,
        "password_hash": password_hash,
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    return {"user_id": user_id, "username": username}


@app.post("/auth/login")
def login(data: LoginIn):
    items = users_table.query(
        IndexName="email-index",
        KeyConditionExpression=Key("email").eq(data.email.lower()),
    )["Items"]
    ok = items and bcrypt.checkpw(data.password.encode(), items[0]["password_hash"].encode())
    if not ok:
        raise HTTPException(status_code=401, detail="البريد أو كلمة المرور غير صحيحة")
    return {"token": create_token(items[0]["user_id"])}


@app.get("/me")
def me(user_id: str = Depends(current_user_id)):
    user = users_table.get_item(Key={"user_id": user_id}).get("Item")
    if not user:
        raise HTTPException(status_code=401, detail="الحساب غير موجود")
    return {"username": user["username"], "email": user["email"]}


@app.get("/messages")
def messages(user_id: str = Depends(current_user_id)):
    res = messages_table.query(
        KeyConditionExpression=Key("recipient_id").eq(user_id),
        ScanIndexForward=False,
        Limit=50,
    )
    return {"items": res["Items"]}


def find_user(username: str):
    items = users_table.query(
        IndexName="username-index",
        KeyConditionExpression=Key("username").eq(username.lower()),
    )["Items"]
    return items[0] if items else None


@app.get("/public/{username}")
def public_profile(username: str):
    if not find_user(username):
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    return {"username": username.lower()}


@app.post("/public/{username}/messages", status_code=202)
def send_message(username: str, data: MessageIn):
    user = find_user(username)
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    sqs.send_message(
        QueueUrl=queue_url(),
        MessageBody=json.dumps({
            "recipient_id": user["user_id"],
            "text": data.text,
            "sender_name": data.sender_name or "مجهول",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }, ensure_ascii=False),
    )
    return {"status": "queued"}

# يجب أن يبقى هذا آخر شيء في الملف
FRONT = Path(__file__).resolve().parents[2] / "frontend"
app.mount("/", StaticFiles(directory=FRONT, html=True), name="frontend")