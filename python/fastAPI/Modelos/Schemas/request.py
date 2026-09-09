from pydantic import BaseModel

from MAM.Schemas.request import MAMRequest
from MART.Schemas.request import MARTRequest


class PlanComercialRequest(BaseModel):
    mam: MAMRequest
    mart: MARTRequest