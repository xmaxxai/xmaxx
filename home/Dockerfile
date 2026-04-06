FROM node:23-alpine AS build
WORKDIR /app
ARG VITE_STRIPE_PRODUCT_ID=""
ARG VITE_STRIPE_PAYMENT_LINK=""
ARG VITE_XMAXX_DEVELOPER_COMMUNITY_URL=""
COPY package*.json ./
RUN npm install
COPY . .
RUN printf "VITE_STRIPE_PRODUCT_ID=%s\nVITE_STRIPE_PAYMENT_LINK=%s\nVITE_XMAXX_DEVELOPER_COMMUNITY_URL=%s\n" \
  "$VITE_STRIPE_PRODUCT_ID" \
  "$VITE_STRIPE_PAYMENT_LINK" \
  "$VITE_XMAXX_DEVELOPER_COMMUNITY_URL" > .env.production
RUN npm run build

FROM nginx:1.29-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
