# Etapa 1: construir la aplicación
FROM node:24-alpine AS build

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos primero los archivos de dependencias para aprovechar la caché
COPY app/package*.json ./

# Si usas pnpm o yarn, aquí cambiarías el comando
RUN npm install

# Copiamos el resto del código fuente
COPY app/ .

# Construimos la app de producción
RUN npm run build

# En el directotio /app/dist está la aplicación compilada

# Etapa 2: imagen ligera con Nginx para servir los archivos estáticos
FROM nginx:1.27-alpine

# Añadimos una configuración simple para una SPA (Vue + Vite)
# COPY default.conf /etc/nginx/conf.d/default.conf

# Copiamos los archivos construidos desde la etapa anterior
COPY --from=build /app/dist /usr/share/nginx/html

# Puerto que expone Nginx
EXPOSE 80

# Comando por defecto (ya definido en la imagen base de nginx)
CMD ["nginx", "-g", "daemon off;"]
