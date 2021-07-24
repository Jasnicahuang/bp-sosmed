FROM php:7.2-apache 
COPY . /var/www/html
RUN docker-php-ext-install mysqli pdo_mysql pdo
RUN apt-get update \
    && apt-get install -y libzip-dev \
    && apt-get install -y zlib1g-dev \
    && apt-get install -y git nano vim \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install zip

EXPOSE 80/tcp
