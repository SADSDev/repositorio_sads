#datos que el usuarioo enviaria

#-----------------------------------
#LIBRERIAS
#-----------------------------------
from pydantic import BaseModel

#----------------------------------------------------
# IMPORTS
#----------------------------------------------------


#----------------------------------------------------------
# DATOS ESPERADOS A INGRESAR POR EL USUARIO
#--------------------------------------------------------
class MetaMarca(BaseModel):
    marca: str
    meta: float

class MAMRequest(BaseModel):
    mes: int
    anio: int
    agencia: int
    meta_neta:float

    marcas_estrategicas: list[MetaMarca]