-- Script para agregar la columna 'password' a la tabla 'usuario'
-- Esta columna almacena la contraseña en texto plano para que el administrador pueda verla

ALTER TABLE usuario 
ADD COLUMN password VARCHAR(255) NULL 
AFTER password_hash;

-- Comentario: La columna password es opcional (NULL) y se usa solo para 
-- que el administrador pueda ver y compartir la contraseña con el usuario al crearlo.

