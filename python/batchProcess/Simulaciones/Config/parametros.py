#-----------------------------------------------------------------------
#LIBRERIAS
#-----------------------------------------------------------------------
from dotenv import load_dotenv

import os

#-----------------------------------------------------------------------
# ENTORNO
#-----------------------------------------------------------------------
load_dotenv()

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