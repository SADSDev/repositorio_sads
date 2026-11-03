#-----------------------------------------------------------------------
#LIBRERIAS
#-----------------------------------------------------------------------
from dotenv import load_dotenv
from pathlib import Path

import os

#-----------------------------------------------------------------------
# ENTORNO
#-----------------------------------------------------------------------
BASE_DIRECTORIO=Path(__file__).resolve().parents[1]#sube 2 niveles hacia carpeta "Modelos"
load_dotenv(BASE_DIRECTORIO / ".env")

#---------------------------------------------------------------------
# PARAMETROS
#---------------------------------------------------------------------
# Credenciales SQL


servidor = os.getenv("SERVER")
bd = os.getenv("DATABASE")
usuario = os.getenv("USER")
contrasena = os.getenv("PASSWORD")

if not all([servidor, bd, usuario, contrasena]):
    raise RuntimeError(
        "Faltan variables de entorno para la conexión a SQL Server."
    )