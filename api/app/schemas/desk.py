from pydantic import BaseModel

from api.app.schemas.citizen import TokenOut


class DeskBookIn(BaseModel):
    office_id: str
    service_id: str
    category: str = "NORMAL"
    phone: str | None = None
    citizen_name: str | None = None
    created_via: str = "ASSISTED"  # ASSISTED or WALKIN


class DeskSlipOut(BaseModel):
    token: TokenOut
    printable_code: str
    qr_data: str
