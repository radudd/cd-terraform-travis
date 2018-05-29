FROM node:9.11-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm install

# Copy all app resourcex
COPY . .

EXPOSE 3000
CMD [ "npm", "start" ]
