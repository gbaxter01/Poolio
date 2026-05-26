FROM node:24-slim

WORKDIR /app

# Install packages
COPY package.json package-lock.json ./
RUN npm ci

# Copy API source code
COPY . .

# Lint before starting
RUN npx eslint .

EXPOSE 8080

CMD ["node", "index.js"]