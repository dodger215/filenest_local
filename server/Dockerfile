FROM node:24-alpine
WORKDIR /app/server
COPY package*.json ./
RUN npm ci --omit=dev
COPY app.js server.js ./
ENV PORT=3001 HOST=0.0.0.0 DATA_DIR=/data
VOLUME /data
EXPOSE 3001
CMD ["node", "server.js"]
