from pydantic import BaseModel


class UserBase(BaseModel):
    email: str
    full_name: str


class UserResponse(UserBase):
    id: int
    is_active: bool

    class Config:
        orm_mode = True
