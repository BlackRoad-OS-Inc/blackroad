FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY features.json /usr/share/nginx/html/features.json
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
