# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
````md
# Event Management System

Sistema de gestión de eventos desarrollado con Ruby on Rails 8.

---

# Stack Tecnológico

- Ruby 3.3.1
- Rails 8.1.3
- PostgreSQL
- TailwindCSS
- Devise
- RSpec
- Dotenv

---

# Requisitos Previos

Antes de clonar el proyecto debes tener instalado:

## macOS

### Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
````

---

## Ruby con rbenv

```bash
brew install rbenv ruby-build
```

Agregar a zsh:

```bash
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc
```

Instalar Ruby:

```bash
rbenv install 3.3.1
rbenv global 3.3.1
```

Verificar:

```bash
ruby -v
```

---

## PostgreSQL

```bash
brew install postgresql
brew services start postgresql
```

---

## Node.js

```bash
brew install node
```

---

# Clonar Proyecto

```bash
git clone URL_DEL_REPOSITORIO
cd event-management
```

---

# Instalar Dependencias

```bash
bundle install
```

---

# Variables de Entorno

Crear archivo `.env`

```bash
touch .env
```

Agregar:

```env
DB_USERNAME=postgres
DB_PASSWORD=TU_PASSWORD
```

---

# Configuración Database

En `config/database.yml` usar:

```yml
default: &default
  adapter: postgresql
  encoding: unicode
  username: <%= ENV["DB_USERNAME"] %>
  password: <%= ENV["DB_PASSWORD"] %>
  host: localhost
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

---

# Crear Base de Datos

```bash
rails db:create
rails db:migrate
```

---

# Ejecutar Proyecto

```bash
rails s
```

Abrir:

```text
http://localhost:3000
```

---

# Estructura del Proyecto

```text
app/
config/
db/
spec/
```

---

# Gems Principales

* devise
* rspec-rails
* dotenv-rails
* tailwindcss-rails

---

# Convenciones Git

## Branches

```text
main
develop
feature/nombre-feature
```

---

# Testing

Ejecutar tests:

```bash
bundle exec rspec
```

---

# Comandos Útiles

## Crear controlador

```bash
rails generate controller NombreControlador
```

## Crear modelo

```bash
rails generate model NombreModelo
```

## Migraciones

```bash
rails db:migrate
```

---

# Equipo de Desarrollo

Mantener:

* Pull Requests
* Código limpio
* Convenciones Rails
* Commits descriptivos
* Variables sensibles en `.env`

---

```
```
