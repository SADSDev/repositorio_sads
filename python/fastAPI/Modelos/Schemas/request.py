#===============================================
# LIBRERIAS
#===============================================
from pydantic import BaseModel

#===============================================
# IMPORTS 
#===============================================
from MAM.Schemas.request import MAMRequest
from MART.Schemas.request import MARTRequest


#===============================================
# MODELO BASE PLAN COMERCIAL (COMBINACION MAM Y MART)
#================================================
class PlanComercialRequest(BaseModel):
    mam: MAMRequest
    mart: MARTRequest