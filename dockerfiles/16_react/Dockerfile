# Etapa 1: build de la aplicación React
FROM node:24-alpine AS build

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos solo los archivos de dependencias para aprovechar la cache
COPY package*.json ./

# Instalamos dependencias (npm ci para builds reproducibles; si no tienes package-lock.json, usa npm install)
RUN npm ci --silent

# Copiamos el resto del código
COPY . .

# Build de producción de la app React
RUN npm run build


# Etapa 2: imagen final con nginx sirviendo los archivos estáticos
FROM nginx:1.29.3-alpine3.22

# Copiamos el build de React a la carpeta pública de nginx
COPY --from=build /app/build /usr/share/nginx/html

# Opcional pero recomendable: sustituir la config por defecto
RUN rm /etc/nginx/conf.d/default.conf
COPY config/nginx.conf /etc/nginx/conf.d/default.conf

# Puerto en el que escuchará nginx
EXPOSE 80

# Comando por defecto de nginx
CMD ["nginx", "-g", "daemon off;"]
