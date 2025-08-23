FROM node:20-slim

# Install security updates
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia solo los archivos de dependencias primero
COPY package*.json ./

# Instala solo dependencias de producción
RUN npm install --only=production

# Copia el resto del código
COPY . .

# Define el entorno de producción
ENV NODE_ENV=production

# Expone el puerto de la app
EXPOSE 3000

# Usa un usuario no root (opcional, recomendado)
# RUN useradd --user-group --create-home --shell /bin/false appuser
# USER appuser

CMD ["npm", "start"]
