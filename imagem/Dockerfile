FROM php:8.3-cli

# Instala o driver do PDO para MySQL
RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /app
COPY . /app

# Cloud Run expõe a porta via $PORT (padrão 8080)
ENV PORT=8080
EXPOSE 8080

# Sobe o servidor embutido do PHP
CMD ["sh","-c","php -S 0.0.0.0:${PORT} /app/index.php"]
