#!/bin/bash

mongosh "mongodb://admin:password_segura@localhost:27017/admin?authSource=admin" --quiet --eval '
db.getRoles({ showBuiltinRoles: true })
'

# Explica varios los roles disponibles en MongoDB incluidos por defecto:
# rol: root, permite realizar cualquier acción en cualquier recurso
# rol: clusterAdmin, permite administrar el clúster de MongoDB
# rol: clusterManager, permite administrar el clúster de MongoDB, pero no tiene permisos para realizar acciones administrativas en las bases de datos
# rol: clusterMonitor, permite monitorear el clúster de MongoDB, pero no tiene permisos para realizar acciones administrativas en las bases de datos
# rol: hostManager, permite administrar hosts en un clúster de MongoDB
# rol: backup, permite realizar copias de seguridad de las bases de datos
# rol: restore, permite restaurar copias de seguridad de las bases de datos
# rol: dbAdmin, combina: readWrite, dbAdmin, userAdmin
# rol: dbOwner, permite realizar cualquier acción en una base de datos específica
# rol: userAdmin, permite administrar usuarios y roles en una base de datos específica
# rol: read, permite leer datos de una base de datos específica
# rol: readWrite, permite leer y escribir datos en una base de datos específica
# rol: readAnyDatabase, Solo lectura en todas las bases de datos
# rol: readWriteAnyDatabase, Leer y escribir en todas las bases
# rol: dbAdminAnyDatabase, permite administrar usuarios y roles en cualquier base de dato
# rol: userAdminAnyDatabase, permite administrar usuarios y roles en cualquier base de datos

