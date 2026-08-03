# Development-only image for the backend workspace. Not optimized for
# production (no multi-stage build, dev dependencies included, source is
# bind-mounted by docker-compose.yml for hot reload via nodemon).
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
