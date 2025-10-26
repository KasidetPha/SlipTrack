from pydantic import BaseModel, Field

class MonthYear(BaseMode):
    month:int = Field(ge=1, le=12)
    year: int