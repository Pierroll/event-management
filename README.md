# SGE - Sistema de Gestión de Eventos

Sistema de gestión de eventos desarrollado con Ruby on Rails 8, diseñado para facilitar la creación, gestión y descubrimiento de eventos de todo tipo.

---

## 📋 Tabla de Contenidos

- [Stack Tecnológico](#stack-tecnológico)
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Requisitos Previos](#requisitos-previos)
- [Instalación por Sistema Operativo](#instalación-por-sistema-operativo)
- [Configuración Inicial](#configuración-inicial)
- [Base de Datos](#base-de-datos)
- [Ejecutar el Proyecto](#ejecutar-el-proyecto)
- [Endpoints y Rutas](#endpoints-y-rutas)
- [Seed Inicial](#seed-inicial)
- [Comandos Útiles](#comandos-útiles)
- [Testing](#testing)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Convenciones Git](#convenciones-git)
- [Deployment](#deployment)

---

## 🚀 Stack Tecnológico

### Backend
- **Ruby 3.3.1** - Lenguaje de programación
- **Rails 8.1.3** - Framework web
- **PostgreSQL** - Base de datos relacional
- **Puma** - Servidor web

### Frontend
- **TailwindCSS 4.4** - Framework CSS
- **Hotwire** (Turbo + Stimulus) - JavaScript moderno sin build step
- **Leaflet** - Mapas interactivos
- **Importmap** - Gestión de módulos JavaScript

### Autenticación y Autorización
- **Devise 5.0** - Autenticación de usuarios
- **Pundit 2.5** - Autorización basada en políticas

### Utilidades
- **Kaminari 1.2** - Paginación
- **Dotenv 3.2** - Variables de entorno
- **RSpec 8.0** - Framework de testing
- **Capybara + Selenium** - Testing de sistema

### Solid Suite (Rails 8)
- **Solid Cache** - Caching con backing de base de datos
- **Solid Queue** - Job queue con backing de base de datos
- **Solid Cable** - Action Cable con backing de base de datos

### Deployment
- **Kamal** - Deployment en containers
- **Docker** - Contenedores
- **Thruster** - HTTP caching y compression

### Seguridad
- **Brakeman** - Análisis de seguridad estático
- **Bundler-audit** - Auditoría de gems vulnerables
- **Rubocop Rails Omakase** - Linting y estilo

---

## 🏗️ Arquitectura del Sistema

### Patrones de Diseño

#### Service Objects
Lógica de negocio compleja encapsulada en servicios:
- `Events::CreateService` - Creación de eventos con imágenes
- `Events::UpdateService` - Actualización de eventos
- `Comments::CreateService` - Creación de comentarios

#### Query Objects
Consultas complejas encapsuladas:
- `Events::SearchQuery` - Búsqueda avanzada de eventos (city, category, query, dates, price)

#### Policies (Pundit)
Autorización por recurso:
- `ApplicationPolicy` - Política base
- `EventPolicy` - Autorización de eventos
- `UserPolicy` - Autorización de usuarios
- `CategoryPolicy` - Autorización de categorías
- `CommentPolicy` - Autorización de comentarios

### Modelos del Dominio

```
User (Devise)
├── has_many :user_roles
├── has_many :roles, through: :user_roles
├── has_many :organized_events (as: organizer)
└── has_many :comments

Role
├── has_many :user_roles
└── has_many :users, through: :user_roles

UserRole (Join Table)
├── belongs_to :user
├── belongs_to :role
└── belongs_to :assigned_by (User, opcional)

Category
└── has_many :events

Event
├── belongs_to :organizer (User)
├── belongs_to :category
├── has_many :event_images
└── has_many :comments

EventImage
├── belongs_to :event
└── has_one_attached :file (Active Storage)

Comment
├── belongs_to :event
└── belongs_to :user
```

### Roles del Sistema

- **admin** - Acceso total al sistema, gestión de usuarios y eventos
- **organizer** - Puede crear y gestionar sus propios eventos
- **registered_user** - Usuario regular que puede ver eventos y comentar

### Namespaces

#### Organizer
- Gestión de eventos propios
- CRUD completo de eventos
- Solo ve sus eventos

#### Admin
- Dashboard de administración
- Gestión de usuarios (asignación de roles)
- Gestión de eventos (todos)
- Gestión de categorías

### Estatus de Eventos

```ruby
enum status: {
  draft: 0,        # Borrador (solo visible para organizer/admin)
  published: 1,    # Publicado (visible para todos)
  canceled: 2,     # Cancelado
  finished: 3     # Finalizado
}
```

---

## 💻 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

### Común a todos los sistemas
- **Git** - Control de versiones
- **Ruby 3.3.1** - Lenguaje de programación
- **PostgreSQL** - Base de datos
- **Node.js** (v18+) - Runtime JavaScript
- **Yarn** o **npm** - Gestor de paquetes JavaScript

---

## 🖥️ Instalación por Sistema Operativo

### macOS

#### 1. Instalar Homebrew (si no lo tienes)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Instalar rbenv y Ruby
```bash
brew install rbenv ruby-build
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc
rbenv install 3.3.1
rbenv global 3.3.1
```

Verificar instalación:
```bash
ruby -v  # Debe mostrar ruby 3.3.1
```

#### 3. Instalar PostgreSQL
```bash
brew install postgresql@16
brew services start postgresql@16
```

#### 4. Instalar Node.js
```bash
brew install node
```

Verificar instalación:
```bash
node -v  # Debe mostrar v18+
npm -v
```

---

### Linux (Ubuntu/Debian)

#### 1. Instalar dependencias del sistema
```bash
sudo apt update
sudo apt install -y git curl build-essential libssl-dev libreadline-dev zlib1g-dev \
  libpq-dev nodejs npm postgresql postgresql-contrib
```

#### 2. Instalar rbenv y Ruby
```bash
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 3.3.1
rbenv global 3.3.1
```

Verificar instalación:
```bash
ruby -v
```

#### 3. Configurar PostgreSQL
```bash
sudo service postgresql start
sudo -u postgres createuser --superuser $USER
createdb
```

#### 4. Verificar Node.js
```bash
node -v
npm -v
```

---

### Windows (WSL2 recomendado)

#### 1. Instalar WSL2 (Ubuntu)
Sigue la guía oficial de Microsoft: https://docs.microsoft.com/windows/wsl/install

#### 2. Dentro de WSL2, seguir los pasos de Linux
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y git curl build-essential libssl-dev libreadline-dev zlib1g-dev \
  libpq-dev nodejs npm postgresql postgresql-contrib

# Instalar rbenv y Ruby
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 3.3.1
rbenv global 3.3.1

# Configurar PostgreSQL
sudo service postgresql start
sudo -u postgres createuser --superuser $USER
createdb
```

---

## 📥 Clonar el Proyecto

```bash
git clone <URL_DEL_REPOSITORIO>
cd event-management
```

---

## ⚙️ Configuración Inicial

### 1. Instalar dependencias de Ruby
```bash
bundle install
```

### 2. Instalar dependencias de JavaScript
```bash
yarn install
# o
npm install
```

### 3. Crear archivo de variables de entorno
```bash
cp .env.example .env
# o crear manualmente
touch .env
```

### 4. Configurar variables de entorno
Editar `.env` con tus credenciales:

```env
# Database
DB_USERNAME=postgres
DB_PASSWORD=tu_password_postgres

# Rails
RAILS_MAX_THREADS=5

# Production (opcional)
EVENT_MANAGEMENT_DATABASE_PASSWORD=tu_password_production
```

### 5. Configurar database.yml
El archivo `config/database.yml` ya está configurado para usar variables de entorno. Verifica que coincidan con tu `.env`:

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

## 🗄️ Base de Datos

### Crear la base de datos
```bash
rails db:create
```

### Ejecutar migraciones
```bash
rails db:migrate
```

### Cargar datos iniciales (Seed)
```bash
rails db:seed
```

### Reset completo (borra todo y recrea)
```bash
rails db:reset
```

### Ver schema actual
```bash
rails db:schema:dump
cat db/schema.rb
```

---

## 🏃 Ejecutar el Proyecto

### Modo Desarrollo
```bash
rails server
# o
rails s
```

Abrir en navegador: `http://localhost:3000`

### Modo con Procfile (recomendado)
```bash
bundle exec foreman start
# o
bin/dev
```

### Verificar que el servidor está corriendo
```bash
curl http://localhost:3000/up
# Debe retornar: OK
```

---

## 🌐 Endpoints y Rutas

### Públicas (Sin autenticación)

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| GET | `/` | `home#index` | Página principal | Landing page |
| GET | `/events` | `events#index` | Listado de eventos | Explorar eventos (con filtros) |
| GET | `/events/:id` | `events#show` | Detalle de evento | Ver evento publicado |
| GET | `/up` | `rails/health#show` | Health check | Verificar estado del servidor |

### Autenticación (Devise)

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET/POST | `/users/sign_in` | Iniciar sesión |
| GET/POST | `/users/sign_up` | Registrarse |
| GET/POST | `/users/password/new` | Recuperar contraseña |
| GET/POST | `/users/confirmation` | Confirmar email |
| DELETE | `/users/sign_out` | Cerrar sesión |

### Perfil de Usuario (Requiere autenticación)

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| GET | `/profile` | `profiles#show` | Ver perfil | Mi perfil |
| GET | `/profile/edit` | `profiles#edit` | Editar perfil | Formulario de edición |
| PATCH/PUT | `/profile` | `profiles#update` | Actualizar perfil | Guardar cambios |

### Comentarios (Requiere autenticación)

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| POST | `/events/:event_id/comments` | `comments#create` | Crear comentario | Comentar en evento |
| DELETE | `/comments/:id` | `comments#destroy` | Eliminar comentario | Borrar comentario propio |

### Organizer (Requiere rol organizer o admin)

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| GET | `/organizer/events` | `organizer/events#index` | Mis eventos | Listado de mis eventos |
| GET | `/organizer/events/new` | `organizer/events#new` | Nuevo evento | Formulario de creación |
| POST | `/organizer/events` | `organizer/events#create` | Crear evento | Guardar nuevo evento |
| GET | `/organizer/events/:id` | `organizer/events#show` | Ver evento | Detalle de mi evento |
| GET | `/organizer/events/:id/edit` | `organizer/events#edit` | Editar evento | Formulario de edición |
| PATCH/PUT | `/organizer/events/:id` | `organizer/events#update` | Actualizar evento | Guardar cambios |
| DELETE | `/organizer/events/:id` | `organizer/events#destroy` | Eliminar evento | Borrar evento |

### Admin (Requiere rol admin)

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| GET | `/admin/dashboard` | `admin/dashboard#index` | Dashboard | Panel de administración |
| GET | `/admin/users` | `admin/users#index` | Usuarios | Listado de usuarios |
| GET | `/admin/users/:id` | `admin/users#show` | Ver usuario | Detalle de usuario |
| GET | `/admin/users/:id/edit` | `admin/users#edit` | Editar usuario | Formulario con roles |
| PATCH/PUT | `/admin/users/:id` | `admin/users#update` | Actualizar usuario | Guardar cambios y roles |
| GET | `/admin/events` | `admin/events#index` | Eventos | Listado de todos los eventos |
| GET | `/admin/events/:id` | `admin/events#show` | Ver evento | Detalle de evento |
| GET | `/admin/events/:id/edit` | `admin/events#edit` | Editar evento | Formulario de edición |
| PATCH/PUT | `/admin/events/:id` | `admin/events#update` | Actualizar evento | Guardar cambios |
| GET | `/admin/categories` | `admin/categories#index` | Categorías | Listado de categorías |
| GET | `/admin/categories/new` | `admin/categories#new` | Nueva categoría | Formulario de creación |
| POST | `/admin/categories` | `admin/categories#create` | Crear categoría | Guardar categoría |
| GET | `/admin/categories/:id/edit` | `admin/categories#edit` | Editar categoría | Formulario de edición |
| PATCH/PUT | `/admin/categories/:id` | `admin/categories#update` | Actualizar categoría | Guardar cambios |
| DELETE | `/admin/categories/:id` | `admin/categories#destroy` | Eliminar categoría | Borrar categoría |

---

## 🌱 Seed Inicial

El seed crea datos de prueba para desarrollo y testing:

### Roles Creados
- `admin` - Administrador del sistema
- `organizer` - Organizador de eventos
- `registered_user` - Usuario regular

### Categorías Creadas
- Tecnología
- Música
- Deportes
- Arte y Cultura
- Gastronomía

### Usuarios de Prueba

| Rol | Email | Password | Nombre |
|-----|-------|----------|--------|
| Admin | `admin@eventos.com` | `admin123` | Admin Principal |
| Organizer | `organizer@eventos.com` | `organizer123` | Organizador Oficial |
| User | `user@eventos.com` | `user123` | Juan Pérez |
| Users extra | `user0@eventos.com` ... `user4@eventos.com` | `password123` | Usuario Falso N |

### Eventos de Prueba
- **Rails World 2026** - Lima, $350 USD (Publicado)
- **Festival de Rock Latino** - Arequipa, $120 PEN (Publicado)
- **Hackathon SGE 2026** - Lima, GRATIS (Publicado)
- **Taller de Pintura Óleo** - Cusco, $150 PEN (Borrador)

### Comentarios de Prueba
- Cada evento publicado tiene 3 comentarios aleatorios con ratings 4-5

### Ejecutar Seed
```bash
rails db:seed
```

### Reset completo con seed
```bash
rails db:reset
# Equivalente a:
rails db:drop db:create db:migrate db:seed
```

---

## 🛠️ Comandos Útiles

### Generadores

#### Crear modelo
```bash
rails generate model NombreModelo campo1:tipo campo2:tipo
# Ejemplo:
rails generate model Product name:string price:decimal description:text
```

#### Crear controlador
```bash
rails generate controller NombreControlador accion1 accion2
# Ejemplo:
rails generate controller Products index show
```

#### Crear migración
```bash
rails generate migration NombreMigracion
# Ejemplo:
rails generate migration AddStatusToProducts status:integer
```

#### Crear scaffold (NO recomendado en este proyecto)
```bash
rails generate scaffold NombreModelo campo1:tipo campo2:tipo
```

### Base de Datos

#### Migraciones
```bash
rails db:migrate              # Ejecutar migraciones pendientes
rails db:rollback             # Revertir última migración
rails db:rollback STEP=3      # Revertir últimas 3 migraciones
rails db:migrate:status       # Ver estado de migraciones
rails db:version              # Ver versión actual
```

#### Seed
```bash
rails db:seed                 # Cargar datos iniciales
rails db:seed:replant         # Recargar seed (borra y recrea)
```

#### Reset
```bash
rails db:reset                # Drop, create, migrate, seed
rails db:drop                 # Eliminar base de datos
rails db:create               # Crear base de datos
```

#### Schema
```bash
rails db:schema:dump          # Generar schema.rb desde DB
rails db:schema:load          # Cargar DB desde schema.rb
```

### Rails Console

#### Iniciar console
```bash
rails console
# o
rails c
```

#### Console en entorno específico
```bash
rails console production
rails console test
```

#### Comandos útiles en console
```ruby
# Crear usuario
User.create!(name: "Juan", email: "juan@test.com", password: "password123")

# Buscar usuario
user = User.find_by(email: "admin@eventos.com")

# Asignar rol
user.roles << Role.find_by(name: "admin")

# Ver eventos
Event.published_only
Event.upcoming
Event.by_city("Lima")

# Crear evento
Event.create!(name: "Mi Evento", description: "Descripción", city: "Lima", 
              address: "Dirección", start_date: 1.week.from_now, 
              category: Category.first, organizer: User.first)
```

### Testing

#### Ejecutar todos los tests
```bash
bundle exec rspec
```

#### Ejecutar tests específicos
```bash
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/controllers/events_controller_spec.rb
```

#### Ejecutar tests con formato detallado
```bash
bundle exec rspec --format documentation
```

#### Ejecutar tests con coverage
```bash
bundle exec rspec --format documentation --format html --out coverage.html
```

### Linting

#### Ejecutar Rubocop
```bash
bundle exec rubocop
```

#### Autocorregir con Rubocop
```bash
bundle exec rubocop -a
```

#### Ver solo errores
```bash
bundle exec rubocop --only Style,Layout
```

### Seguridad

#### Ejecutar Brakeman
```bash
bundle exec brakeman
```

#### Ejecutar Brakeman con reporte HTML
```bash
bundle exec brakeman -o brakeman-report.html
```

#### Ejecutar Bundler-audit
```bash
bundle exec bundler-audit check
```

#### Actualizar gems vulnerables
```bash
bundle exec bundler-audit update
```

### Logs

#### Ver logs de desarrollo
```bash
tail -f log/development.log
```

#### Limpiar logs
```bash
rails log:clear
```

#### Ver logs de producción
```bash
tail -f log/production.log
```

### Assets

#### Precompilar assets
```bash
rails assets:precompile
```

#### Limpiar assets
```bash
rails assets:clean
rails assets:clobber
```

### Cache

#### Limpiar cache
```bash
rails tmp:clear
rails cache:clear
```

### Routes

#### Ver todas las rutas
```bash
rails routes
```

#### Buscar rutas específicas
```bash
rails routes | grep admin
rails routes | grep events
```

#### Ver rutas en formato compacto
```bash
rails routes --compact
```

---

## 🧪 Testing

### Configuración de RSpec

El proyecto usa RSpec 8.0 para testing.

### Estructura de Specs

```
spec/
├── models/           # Tests de modelos
│   ├── user_spec.rb
│   ├── event_spec.rb
│   └── ...
├── controllers/      # Tests de controladores
├── policies/         # Tests de políticas
├── requests/         # Tests de requests
├── features/         # Tests de integración
├── rails_helper.rb   # Configuración de Rails
└── spec_helper.rb    # Configuración de RSpec
```

### Ejecutar Tests

```bash
# Todos los tests
bundle exec rspec

# Tests de un archivo específico
bundle exec rspec spec/models/user_spec.rb

# Tests de una línea específica
bundle exec rspec spec/models/user_spec.rb:15

# Tests con formato documentation
bundle exec rspec --format documentation

# Tests con fallas primero
bundle exec rspec --order failed
```

### System Testing con Capybara

```bash
# Ejecutar system tests
bundle exec rspec spec/system/

# System tests con headless Chrome
HEADLESS=chrome bundle exec rspec spec/system/
```

---

## 📁 Estructura del Proyecto

```
event-management/
├── app/
│   ├── assets/              # Assets estáticos (imágenes, fuentes)
│   ├── controllers/         # Controladores
│   │   ├── admin/          # Namespace admin
│   │   │   ├── base_controller.rb
│   │   │   ├── dashboard_controller.rb
│   │   │   ├── users_controller.rb
│   │   │   ├── events_controller.rb
│   │   │   └── categories_controller.rb
│   │   ├── organizer/      # Namespace organizer
│   │   │   ├── base_controller.rb
│   │   │   └── events_controller.rb
│   │   ├── application_controller.rb
│   │   ├── events_controller.rb
│   │   ├── comments_controller.rb
│   │   ├── home_controller.rb
│   │   └── profiles_controller.rb
│   ├── helpers/            # View helpers
│   ├── javascript/        # JavaScript (Stimulus controllers)
│   │   ├── controllers/
│   │   │   ├── application.js
│   │   │   ├── explore_controller.js
│   │   │   ├── event_form_controller.js
│   │   │   ├── event_detail_controller.js
│   │   │   ├── flash_controller.js
│   │   │   └── organizer_dashboard_controller.js
│   │   └── application.js
│   ├── jobs/               # Active Job jobs
│   ├── mailers/            # Mailers
│   ├── models/             # Modelos ActiveRecord
│   │   ├── application_record.rb
│   │   ├── user.rb
│   │   ├── role.rb
│   │   ├── user_role.rb
│   │   ├── category.rb
│   │   ├── event.rb
│   │   ├── event_image.rb
│   │   └── comment.rb
│   ├── policies/           # Pundit policies
│   │   ├── application_policy.rb
│   │   ├── event_policy.rb
│   │   ├── user_policy.rb
│   │   ├── category_policy.rb
│   │   └── comment_policy.rb
│   ├── queries/            # Query objects
│   │   └── events/
│   │       └── search_query.rb
│   ├── services/           # Service objects
│   │   ├── events/
│   │   │   ├── create_service.rb
│   │   │   └── update_service.rb
│   │   └── comments/
│   │       └── create_service.rb
│   └── views/              # Vistas ERB
│       ├── layouts/
│       ├── admin/
│       ├── organizer/
│       ├── events/
│       ├── devise/
│       └── shared/
├── bin/                    # Ejecutables Rails
│   ├── rails
│   ├── rake
│   ├── setup
│   ├── dev
│   └── ...
├── config/                 # Configuración
│   ├── application.rb
│   ├── database.yml
│   ├── routes.rb
│   ├── environments/
│   ├── initializers/
│   └── locales/
├── db/                     # Base de datos
│   ├── migrate/           # Migraciones
│   ├── seeds.rb           # Datos iniciales
│   └── schema.rb          # Schema actual
├── lib/                    # Librerías personalizadas
├── log/                    # Logs
├── public/                 # Archivos públicos
├── spec/                   # Tests RSpec
│   ├── models/
│   ├── controllers/
│   ├── policies/
│   ├── rails_helper.rb
│   └── spec_helper.rb
├── storage/                # Active Storage
├── test/                   # Tests Rails (si existen)
├── tmp/                    # Archivos temporales
├── vendor/                 # Gems vendorizadas
├── .env                    # Variables de entorno (NO commitear)
├── .env.example            # Ejemplo de .env
├── .gitignore              # Archivos ignorados por Git
├── .ruby-version           # Versión de Ruby
├── Dockerfile              # Configuración Docker
├── Gemfile                 # Dependencias Ruby
├── Gemfile.lock            # Versiones bloqueadas
├── Procfile.dev            # Procfile para desarrollo
├── Rakefile                # Tareas Rake
├── README.md               # Este archivo
└── config.ru               # Configuración Rack
```

---

## 🌿 Convenciones Git

### Branch Strategy

```text
main          → Producción
develop       → Desarrollo integrado
feature/*     → Nuevas funcionalidades
bugfix/*      → Corrección de bugs
hotfix/*      → Correcciones urgentes en producción
```

### Flujo de Trabajo

1. Crear branch desde `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/nombre-feature
   ```

2. Hacer commits con mensajes descriptivos
   ```bash
   git add .
   git commit -m "feat: agregar búsqueda de eventos por ciudad"
   ```

3. Push al branch
   ```bash
   git push origin feature/nombre-feature
   ```

4. Crear Pull Request a `develop`

5. Code review y aprobación

6. Merge a `develop`

7. Deploy desde `develop` a `main`

### Convención de Commits (Conventional Commits)

```text
feat:     nueva funcionalidad
fix:      corrección de bug
docs:     cambios en documentación
style:    cambios de formato (sin lógica)
refactor: refactorización de código
test:     agregar o modificar tests
chore:    tareas de mantenimiento
```

Ejemplos:
```bash
git commit -m "feat: agregar filtro de eventos por precio"
git commit -m "fix: corregir validación de fecha fin en eventos"
git commit -m "docs: actualizar README con nuevas instrucciones"
git commit -m "refactor: simplificar lógica de búsqueda de eventos"
```

---

## 🚢 Deployment

### Kamal (Recomendado)

El proyecto está configurado para deployment con Kamal.

#### Instalar Kamal
```bash
gem install kamal
```

#### Inicializar Kamal (si no está inicializado)
```bash
kamal init
```

#### Configurar `config/deploy.yml`
El archivo ya existe. Verifica la configuración:
- Servidor de destino
- Imagen Docker
- Variables de entorno
- Comandos de pre-deployment

#### Deploy
```bash
kamal deploy
```

#### Ver logs del servidor
```bash
kamal app logs
```

#### Ejecutar comandos en el servidor
```bash
kamal app exec "rails console"
kamal app exec "rails db:migrate"
```

### Docker

#### Construir imagen
```bash
docker build -t event-management .
```

#### Ejecutar contenedor
```bash
docker run -p 3000:3000 \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=password \
  event-management
```

### Variables de Entorno en Producción

```env
# Database
DB_USERNAME=postgres
DB_PASSWORD=tu_password_seguro
RAILS_MAX_THREADS=5

# Rails Secret
RAILS_MASTER_KEY=tu_master_key
SECRET_KEY_BASE=tu_secret_key_base

# Production Database
EVENT_MANAGEMENT_DATABASE_PASSWORD=tu_password_production

# Otros
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
```

---

## 🔒 Seguridad

### Variables Sensibles

**NUNCA** commitear:
- `.env` - Usa `.env.example` como plantilla
- `config/master.key` - Ya está en `.gitignore`
- Contraseñas hardcodeadas
- API keys

### Auditoría de Seguridad

Ejecutar regularmente:
```bash
bundle exec brakeman
bundle exec bundler-audit check
```

### Headers de Seguridad

El proyecto incluye:
- CSP (Content Security Policy)
- CSRF protection
- Secure headers (configurados en Rails 8)

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Rails Guides](https://guides.rubyonrails.org/)
- [Devise Wiki](https://github.com/heartcombo/devise/wiki)
- [Pundit Documentation](https://github.com/varvet/pundit)
- [TailwindCSS](https://tailwindcss.com/docs)
- [Hotwire](https://hotwired.dev/)

### Comunidad
- [Ruby on Rails Forum](https://discuss.rubyonrails.org/)
- [Stack Overflow - Ruby on Rails](https://stackoverflow.com/questions/tagged/ruby-on-rails)

---

## 👥 Equipo de Desarrollo

Mantener buenas prácticas:

- ✅ Pull Requests con descripción clara
- ✅ Código limpio y legible
- ✅ Convenciones de Rails
- ✅ Commits descriptivos (Conventional Commits)
- ✅ Variables sensibles en `.env`
- ✅ Tests para nuevas funcionalidades
- ✅ Code review antes de merge
- ✅ Documentar cambios complejos

---

## 📝 Licencia

[Agregar licencia del proyecto aquí]

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crear branch para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'feat: add AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

---

## 📞 Soporte

Para preguntas o problemas:
- Crear issue en el repositorio
- Contactar al equipo de desarrollo
- Revisar documentación oficial

---

**Última actualización:** Mayo 2026
