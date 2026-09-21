-- BBDD separada para el metastore propio de HUE (usuarios, historial,
-- documentos guardados). No mezcla datos del laboratorio con los del
-- Módulo 3/4 en "auditoria" — ver hue/conf/zz-course-overrides.ini.
-- Nombrada con prefijo "00_" para que se ejecute antes que 01_operaciones.sql
-- (los scripts de /docker-entrypoint-initdb.d se procesan en orden alfabético).

CREATE DATABASE hue OWNER auditor;
