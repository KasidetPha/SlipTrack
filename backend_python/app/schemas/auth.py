from pydantic import BaseModel

class LoginRequest(BaseModel):
    email: str
    password: str
    
class LoginResponse(BaseModel):
    message: str = "Login success"
    token: str