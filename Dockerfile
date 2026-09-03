# --- БЛОК 25/30: DOCKERFILE ДЛЯ BACKEND СЕРВЕРА ---
# Збережіть цей блок у файл: Dockerfile

FROM node:20-alpine

# Робоча директорія
WORKDIR /usr/src/app

# Копіюємо конфігурації залежностей
COPY package*.json ./

# Встановлюємо залежності
RUN npm install --production

# Копіюємо весь вихідний код
COPY . .

# Відкриваємо порт
EXPOSE 3000

# Запуск сервера
CMD ["node", "server.js"]
