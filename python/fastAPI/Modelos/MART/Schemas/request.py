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
class MARTRequest(BaseModel):
    mes: int
    anio: int
    agencia: int
