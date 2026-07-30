#Este proceso reusable sirve para validar los df´s obtenidos 
#en el proceso de un modelo


#-----------------------------------------------------
#LIBRERIAS
#-----------------------------------------------------
import logging
logger = logging.getLogger("uvicorn.error")

import pandas as pd

#-----------------------------------------------------
#IMPORTS
#-----------------------------------------------------
from Core.exceptions import ErrorDatosModelo

#-----------------------------------------------------
# PROCESO DE VALIDACION DE DF´S
#-----------------------------------------------------
def validar_dataframe(
    dataframe: pd.DataFrame | None,
    nombre: str
):
    if dataframe is None or dataframe.empty:

        raise ErrorDatosModelo(nombre)