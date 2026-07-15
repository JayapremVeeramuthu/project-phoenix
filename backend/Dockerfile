# Base stage for building
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Install build tools and openssl for Prisma compatibility
RUN apk add --no-cache python3 make g++ openssl

COPY package*.json ./
RUN npm install

COPY prisma ./prisma/
RUN npx prisma generate

COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /usr/src/app

# Install openssl and curl for health checks
RUN apk add --no-cache openssl curl

COPY package*.json ./
RUN npm install --omit=dev

# Install prisma client specifically
RUN npm install @prisma/client

COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /usr/src/app/node_modules/@prisma/client ./node_modules/@prisma/client
COPY prisma ./prisma
COPY --from=builder /usr/src/app/firebase ./firebase

EXPOSE 3000

CMD ["npm", "run", "start:prod"]
