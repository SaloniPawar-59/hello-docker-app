# Simple Nginx-based static site
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
