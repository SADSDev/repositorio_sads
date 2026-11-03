#===============================================
# LIBRERIAS
#===============================================
from pydantic import BaseModel

#===============================================
# IMPORTS 
#===============================================
from fastAPI.Modelos.MAM.Schemas.request import MAMRequest
from fastAPI.Modelos.MART.Schemas.request import MARTRequest


#===============================================
# MODELO BASE PLAN COMERCIAL (COMBINACION MAM Y MART)
#================================================
class PlanComercialRequest(BaseModel):
    mam: MAMRequest
    mart: MARTRequest