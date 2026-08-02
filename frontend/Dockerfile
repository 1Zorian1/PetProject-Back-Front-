FROM nginx:alpine

# Копіюємо наш Reverse Proxy конфіг замість дефолтного
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Копіюємо HTML файл
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
