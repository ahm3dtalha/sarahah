from pydantic import BaseModel, ConfigDict, EmailStr, Field


class MessageIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    text: str = Field(min_length=1, max_length=500)
    sender_name: str = Field(default="", max_length=30)

class RegisterIn(BaseModel):
    username: str = Field(min_length=3, max_length=20, pattern="^[a-zA-Z0-9_]+$")
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)
class LoginIn(BaseModel):
    email: EmailStr
    password: str