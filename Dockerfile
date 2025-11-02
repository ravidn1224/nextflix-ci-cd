FROM node:18.0.0-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . .
ENV NODE_OPTIONS=--openssl-legacy-provider

RUN npm install
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
