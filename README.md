# SGE - Sistema de Gestión de Eventos

Sistema de gestión de eventos desarrollado con Ruby on Rails 8, diseñado para facilitar la creación, gestión y descubrimiento de eventos de todo tipo.

---

## 📋 Tabla de Contenidos

- [Stack Tecnológico](#stack-tecnológico)
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Autenticación y Flujo de Registro](#autenticación-y-flujo-de-registro)
- [Requisitos Previos](#requisitos-previos)
- [Instalación por Sistema Operativo](#instalación-por-sistema-operativo)
- [Configuración Inicial](#configuración-inicial)
- [Base de Datos](#base-de-datos)
- [Ejecutar el Proyecto](#ejecutar-el-proyecto)
- [Tailwind CSS](#tailwind-css)
- [Mapas con Leaflet](#mapas-con-leaflet)
- [Endpoints y Rutas](#endpoints-y-rutas)
- [Seed Inicial](#seed-inicial)
- [Comandos Útiles](#comandos-útiles)
- [Testing](#testing)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Rate Limiting](#rate-limiting)
- [Convenciones Git](#convenciones-git)
- [Deployment](#deployment)
- [Seguridad](#seguridad)
- [Recursos Adicionales](#recursos-adicionales)

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
- **Leaflet** - Mapas interactivos (CSS vía CDN unpkg.com)
- **Importmap** - Gestión de módulos JavaScript

### Autenticación y Autorización
- **Devise 5.0** - Autenticación de usuarios
- **Pundit 2.5** - Autorización basada en políticas
- **omniauth-google-oauth2 ~> 1.2** - Autenticación con Google OAuth

### Utilidades
- **Kaminari 1.2** - Paginación
- **Geocoder ~> 1.8** - Geocodificación de direcciones de eventos
- **Dotenv ~> 3.2** - Variables de entorno
- **rails-i18n ~> 8.0** - Internacionalización
- **RSpec 8.0** - Framework de testing
- **Capybara + Selenium** - Testing de sistema

### Pagos
- **Culqi** - Pasarela de pagos (API v4)
- **PaymentGateway** - Patrón Gateway abstracto (MockGateway + CulqiGateway)
- **Solid Queue recurring jobs** - Expiración automática de reservas

### Desarrollo
- **Letter Opener** - Vista previa de emails en desarrollo
- **Web Console** - Consola interactiva en páginas de error

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

- `ConfirmationCodeService` - Manejo de códigos de verificación email:
  - Genera código de 6 dígitos, almacena hash SHA256
  - Expira a los 15 minutos
  - Máximo 3 intentos de verificación
  - Reintento con cooldown de 60 segundos
- `Events::CreateService` - Creación de eventos con imágenes (Active Storage + URL legacy)
- `Events::UpdateService` - Actualización de eventos con reemplazo de imágenes
- `Comments::CreateService` - Creación de comentarios con validación
- `ExpireBookingsJob` (recurring via Solid Queue cada 5 min):
  - Expira reservas `pending` cuyo `expires_at` venció
  - Excluye reservas con un Payment en estado `pending` (protege pagos en curso)
  - Usa `update_all` atómico (única sentencia SQL)
- `BookingService` - Creación de reservas con control de capacidad:
  - Bloqueo pesimista (`lock!`) sobre evento y ticket_type
  - Verifica `#available?` y `#remaining_capacity`
  - Transacción atómica
- `PaymentGateway` (Module + Base Class) — Patrón Gateway abstracto:
  - `Base#charge(amount_cents:, currency_code:, description:, email:, source_id:)` — interfaz
  - `instance` — singleton resuelto via `ENV["PAYMENT_GATEWAY"]`
  - `MockGateway` — para dev/test, simula aprobado/declinado según prefijo de tarjeta
- `Payments::ChargeService` — Procesamiento de pago:
  - Bloqueo pesimista (`with_lock`) sobre booking (previene doble cobro)
  - Monto recalculado del lado servidor (`quantity * unit_price * 100`)
  - Re-chequea `expired_unpaid?` y `confirmed?` dentro del lock
  - Crea Payment y actualiza Booking status atómicamente

#### Query Objects
Consultas complejas encapsuladas:
- `Events::SearchQuery` - Búsqueda avanzada de eventos por: city, category, query (texto), fechas (start_date, end_date), price (min/max)

#### Policies (Pundit)
Autorización por recurso:
- `ApplicationPolicy` - Política base
- `EventPolicy` - Autorización de eventos
- `UserPolicy` - Autorización de usuarios
- `CategoryPolicy` - Autorización de categorías
- `CommentPolicy` - Autorización de comentarios

### Modelos del Dominio

```
User (Devise + Omniauth)
├── has_many :user_roles
├── has_many :roles, through: :user_roles
├── has_many :organized_events (as: organizer)
├── has_many :comments
├── has_many :bookings
├── confirmation_code (SHA256 hashed)
├── confirmation_sent_at
├── confirmation_attempts
└── confirmed_at

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
├── has_many :comments
├── has_many :ticket_types
├── has_many :bookings
└── enum status: draft(0), published(1), canceled(2), finished(3)

TicketType
├── belongs_to :event
├── has_many :bookings
├── price, quantity_total, max_per_order
├── sales_start_at / sales_end_at
└── #available? / #remaining_capacity

Booking
├── belongs_to :user
├── belongs_to :event
├── belongs_to :ticket_type
├── has_one :payment, dependent: :destroy
├── quantity, unit_price
├── booked_at, expires_at
├── enum status: pending(0), confirmed(1), cancelled(2), expired(3)
├── before_create :set_booked_at
├── before_create :set_expiration (15 min, if pending)
└── #expired_unpaid?

Payment
├── belongs_to :booking
├── provider (MockGateway / CulqiGateway, etc.)
├── provider_charge_id (unique, nullable)
├── status enum: pending(0), approved(1), declined(2), refunded(3)
├── raw_response (JSONB)
├── UNIQUE index on booking_id (protege doble cobro)
├── UNIQUE partial index on provider_charge_id WHERE NOT NULL
└── State machine: ALLOWED_TRANSITIONS con #can_transition_to?

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

### Estatus de Bookings

```ruby
enum status: {
  pending: 0,      # Esperando pago
  confirmed: 1,    # Pagado / confirmado
  cancelled: 2,    # Cancelado por usuario o sistema
  expired: 3       # Expiró antes de pagar
}
```

### Estatus de Payments (Máquina de Estados)

```ruby
enum status: {
  pending: 0,      # Pago iniciado (procesando)
  approved: 1,     # Pago aprobado
  declined: 2,     # Pago rechazado
  refunded: 3      # Reembolsado
}

# Transiciones permitidas (protege contra webhooks out-of-order):
#   pending  → approved, declined
#   approved → declined, refunded
#   declined → (ninguna — terminal)
#   refunded → (ninguna — terminal)
```

---

## 🔐 Autenticación y Flujo de Registro

### Registro vía Email con Confirmación

El sistema implementa confirmación de email **custom** (NO usa `Devise :confirmable`).

1. El usuario selecciona su rol (Asistir / Organizar)
2. Completa el formulario de registro con email y contraseña
3. Se envía un código de verificación de 6 dígitos vía `UserMailer#confirmation_code`
4. El código se almacena como hash SHA256 con expiración de 15 minutos y máximo 3 intentos
5. El usuario ingresa el código en `/confirmation/verify`
6. Si es correcto, se confirma la cuenta (`confirmed_at` se setea) y se redirige al dashboard

### Registro vía Google OAuth

1. El usuario selecciona su rol (Asistir / Organizar)
2. Hace clic en "Continuar con Google"
3. Se envía una solicitud `POST /users/auth/google_oauth2/with_role` que guarda `session[:pending_role]` y redirige a Google
4. Google callback en `/users/auth/google_oauth2/callback`
5. Si el email ya existe, se asigna el rol pendiente y se inicia sesión
6. Si es nuevo, se crea el usuario con datos de Google, se asigna el rol y se confirma automáticamente

### Flujo OAuth con Rol

```
Usuario → selecciona rol → clic "Continuar con Google"
  → POST /users/auth/google_oauth2/with_role
    → session[:pending_role] = rol_seleccionado
    → redirect_to /users/auth/google_oauth2
      → Google callback → Users::OmniauthCallbacksController
        → asigna pending_role al usuario
        → inicia sesión
```

---

## 💻 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

### Común a todos los sistemas
- **Git** - Control de versiones
- **Ruby 3.3.1** - Lenguaje de programación
- **PostgreSQL** - Base de datos

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

---

### Linux (Ubuntu/Debian)

#### 1. Instalar dependencias del sistema
```bash
sudo apt update
sudo apt install -y git curl build-essential libssl-dev libreadline-dev zlib1g-dev \
  libpq-dev postgresql postgresql-contrib
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
  libpq-dev postgresql postgresql-contrib

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

### 2. Crear archivo de variables de entorno
```bash
touch .env
```

### 3. Configurar variables de entorno
Editar `.env` con tus credenciales:

```env
# Database
DB_USERNAME=postgres
DB_PASSWORD=tu_password_postgres

# Rails
RAILS_MAX_THREADS=5

# Google OAuth
GOOGLE_CLIENT_ID=tu_google_client_id
GOOGLE_CLIENT_SECRET=tu_google_client_secret

# SMTP (Gmail)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=tu_email@gmail.com
SMTP_PASSWORD=tu_app_password
MAILER_SENDER=SGE <noreply@tudominio.com>

# App
APP_HOST=actify.qd.je
APP_PROTOCOL=http

# Pagos (Culqi)
CULQI_PUBLIC_KEY=pk_test_tu_public_key
PAYMENT_GATEWAY=MockGateway    # Cambiar a CulqiGateway para integración real

# Production (opcional)
EVENT_MANAGEMENT_DATABASE_PASSWORD=tu_password_production
```

### 4. Configurar database.yml
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

### Modo Desarrollo (recomendado)
```bash
bin/dev
```
Esto levanta el servidor Rails **y** el watcher de Tailwind CSS simultáneamente.

### Servidor solo
```bash
rails server
# o
rails s
```

Abrir en navegador: `https://actify.qd.je`

### Verificar que el servidor está corriendo
```bash
curl https://actify.qd.je/up
# Debe retornar: OK
```

---

## 🎨 Tailwind CSS

### Tailwind v4

El proyecto usa **TailwindCSS v4** con `@import "tailwindcss"` en el archivo CSS principal. No existe archivo `tailwind.config.js` — la configuración se maneja directamente en CSS.

### Safelist para JS dinámico

Las clases que se togglean desde JavaScript (como `hidden`, `flex`, colores dinámicos) se safelistean con `@source inline()` directamente en el CSS:

```css
@import "tailwindcss";

@source inline(".hidden");
@source inline(".flex");
```

Esto evita que PurgeCSS elimine clases usadas solo en runtime por Stimulus controllers.

### Compilación manual

```bash
bin/rails tailwindcss:build
```

### Watcher automático

`bin/dev` ejecuta el Procfile.dev que corre `bin/rails tailwindcss:watch` en paralelo al servidor, recompilando automáticamente al detectar cambios.

---

## 🗺️ Mapas con Leaflet

Los mapas interactivos se renderizan en la página de detalle del evento usando **Leaflet** con CSS cargado desde CDN (unpkg.com).

- La inicialización del mapa se maneja mediante **Stimulus controllers**
- `event_map_controller.js` - Renderiza el mapa con marcador en la ubicación del evento
- Las coordenadas se obtienen via **Geocoder** al crear/actualizar un evento

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
| DELETE | `/users/sign_out` | Cerrar sesión |
| PATCH | `/users` | Actualizar usuario (Devise RegistrationsController#update) |
| DELETE | `/users` | Cancelar cuenta (Devise RegistrationsController#destroy) |

### Confirmación de Email

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| GET | `/confirmation/new` | `confirmations#new` | Formulario de confirmación | Ingresar código |
| POST | `/confirmation` | `confirmations#create` | Enviar código | Enviar código al email |
| POST | `/confirmation/verify` | `confirmations#verify` | Verificar código | Validar código de 6 dígitos |
| POST | `/confirmation/resend` | `confirmations#resend` | Reenviar código | Reenviar con cooldown de 60s |

### OAuth (Google)

| Método | Ruta | Controlador | Descripción |
|--------|------|-------------|-------------|
| GET | `/users/auth/google_oauth2/callback` | `users/omniauth_callbacks#google_oauth2` | Callback de Google |
| POST | `/users/auth/google_oauth2/with_role` | `users/omniauth_callbacks#authorize_with_role` | Inicia OAuth con rol en sesión |

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

### Bookings y Pagos (Requiere autenticación)

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| GET | `/events/:event_id/bookings/new` | `bookings#new` | Nueva reserva | Formulario de reserva |
| POST | `/events/:event_id/bookings` | `bookings#create` | Crear reserva | Crear reserva con lock pesimista |
| GET | `/bookings` | `bookings#index` | Mis reservas | Listado de reservas del usuario |
| GET | `/bookings/:id` | `bookings#show` | Ver reserva | Detalle de reserva |
| GET | `/bookings/:booking_id/payments/new` | `payments#new` | Checkout | Página de pago con Culqi |
| POST | `/bookings/:booking_id/payments` | `payments#create` | Procesar pago | Cobro con lock + validación |

### Webhooks (Sin autenticación — callback del proveedor de pagos)

| Método | Ruta | Controlador | Acción | Descripción |
|--------|------|-------------|--------|-------------|
| POST | `/webhooks/payments/receive` | `webhooks/payments#receive` | Webhook | Recibe eventos del proveedor de pagos |

El endpoint de webhook valida transiciones de estado vía máquina de estados (`ALLOWED_TRANSITIONS`) para ignorar eventos out-of-order (ej. "approved" que llega después de "refunded").

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
| Admin | `admin@admin.com` | `admin123` | Admin General |
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

### Cobertura Actual

**265 tests** — 0 failures — Modelos, requests, servicios, jobs, policies y mailers.

### Recurring Jobs (Solid Queue)

Configurados en `config/recurring.yml`:

| Job | Schedule | Descripción |
|-----|----------|-------------|
| `ExpireBookingsJob` | Cada 5 minutos | Expira reservas pending cuyo timer venció (excluye con pagos en curso) |

### Testing

#### Ejecutar todos los tests
```bash
bundle exec rspec
```

#### Ejecutar tests específicos
```bash
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/requests/events_spec.rb
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

### Tailwind CSS

#### Compilar manualmente
```bash
bin/rails tailwindcss:build
```

#### Watcher automático
```bash
bin/rails tailwindcss:watch
```

---

## 🧪 Testing

### Configuración de RSpec

El proyecto usa RSpec 8.0 para testing.

### Estructura de Specs

```
spec/
├── models/                     # Tests de modelos
│   ├── user_spec.rb
│   ├── event_spec.rb
│   ├── booking_spec.rb
│   ├── payment_spec.rb
│   ├── comment_spec.rb
│   ├── category_spec.rb
│   ├── event_image_spec.rb
│   ├── event_map_spec.rb
│   ├── role_spec.rb
│   ├── ticket_type_spec.rb
│   └── user_role_spec.rb
├── requests/                   # Tests de requests
│   ├── events_spec.rb
│   ├── bookings_spec.rb
│   ├── payments/
│   │   └── payments_spec.rb
│   ├── webhooks/
│   │   └── payments_spec.rb
│   ├── omniauth_callbacks_spec.rb
│   ├── confirmations_spec.rb
│   ├── home_spec.rb
│   ├── location_spec.rb
│   └── organizer/
├── policies/                   # Tests de políticas
│   ├── event_policy_spec.rb
│   ├── user_policy_spec.rb
│   ├── category_policy_spec.rb
│   ├── booking_policy_spec.rb
│   └── comment_policy_spec.rb
├── services/                   # Tests de servicios
│   ├── confirmation_code_service_spec.rb
│   ├── payment_gateway_spec.rb
│   └── payments/
│       └── charge_service_spec.rb
├── jobs/                       # Tests de jobs
│   └── expire_bookings_job_spec.rb
├── mailers/                    # Tests de mailers
│   └── user_mailer_spec.rb
├── support/                    # Soporte para tests
│   └── omniauth.rb
├── rails_helper.rb             # Configuración de Rails
└── spec_helper.rb              # Configuración de RSpec
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
│   │   ├── users/          # Devise overrides + Omniauth
│   │   │   ├── omniauth_callbacks_controller.rb
│   │   │   └── registrations_controller.rb
│   │   ├── webhooks/       # Webhooks de proveedores externos
│   │   │   └── payments_controller.rb
│   │   ├── application_controller.rb
│   │   ├── bookings_controller.rb
│   │   ├── confirmations_controller.rb
│   │   ├── events_controller.rb
│   │   ├── comments_controller.rb
│   │   ├── home_controller.rb
│   │   ├── payments_controller.rb
│   │   └── profiles_controller.rb
│   ├── helpers/            # View helpers
│   ├── javascript/        # JavaScript (Stimulus controllers)
│   │   ├── controllers/
│   │   │   ├── application.js
│   │   │   ├── index.js
│   │   │   ├── carousel_controller.js
│   │   │   ├── confirm_controller.js
│   │   │   ├── event_detail_controller.js
│   │   │   ├── event_form_controller.js
│   │   │   ├── event_map_controller.js
│   │   │   ├── explore_controller.js
│   │   │   ├── flash_controller.js
│   │   │   ├── location_controller.js
│   │   │   ├── navbar_controller.js
│   │   │   └── organizer_dashboard_controller.js
│   │   └── application.js
│   ├── jobs/               # Active Job jobs
│   │   ├── application_job.rb
│   │   └── expire_bookings_job.rb  # Recurre cada 5 min vía Solid Queue
│   ├── mailers/            # Mailers
│   │   └── user_mailer.rb
│   ├── models/             # Modelos ActiveRecord
│   │   ├── application_record.rb
│   │   ├── user.rb
│   │   ├── role.rb
│   │   ├── user_role.rb
│   │   ├── category.rb
│   │   ├── event.rb
│   │   ├── event_image.rb
│   │   ├── comment.rb
│   │   ├── ticket_type.rb
│   │   ├── booking.rb
│   │   └── payment.rb
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
│   │   ├── booking_service.rb
│   │   ├── confirmation_code_service.rb
│   │   ├── payment_gateway.rb           # Module + Base class
│   │   ├── payment_gateway/
│   │   │   └── mock_gateway.rb          # Mock para dev/test
│   │   ├── payments/
│   │   │   └── charge_service.rb        # Cobro con lock pesimista
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
│       ├── confirmations/
│       ├── profiles/
│       ├── payments/
│       │   └── new.html.erb     # Checkout con Culqi + timer
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
│   ├── requests/
│   ├── policies/
│   ├── services/
│   ├── mailers/
│   ├── support/
│   ├── rails_helper.rb
│   └── spec_helper.rb
├── storage/                # Active Storage
├── test/                   # Tests Rails (si existen)
├── tmp/                    # Archivos temporales
├── vendor/                 # Gems vendorizadas
├── .env                    # Variables de entorno (NO commitear)
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

### Stimulus Controllers

El proyecto usa los siguientes controladores Stimulus:

| Controller | Descripción |
|------------|-------------|
| `explore_controller.js` | Búsqueda y filtros en exploración de eventos |
| `event_form_controller.js` | Formulario de creación/edición de eventos |
| `event_detail_controller.js` | Interacciones en detalle de evento |
| `event_map_controller.js` | Renderizado de mapa Leaflet |
| `flash_controller.js` | Auto-dismiss de mensajes flash |
| `organizer_dashboard_controller.js` | Dashboard del organizador |
| `confirm_controller.js` | Confirmación de email (código de 6 dígitos) |
| `carousel_controller.js` | Carrusel de imágenes de evento |
| `location_controller.js` | Selección de ubicación con autocompletado |
| `navbar_controller.js` | Comportamiento de la barra de navegación |
| `checkout_timer_controller.js` | Cuenta regresiva en checkout de pago (15 min) |

---

## ⏱️ Rate Limiting

Actualmente **no hay rate limiting implementado** en la aplicación. Esto es una consideración futura para:

- Endpoints de confirmación de email (evitar abuso de envío de códigos)
- Creación de comentarios
- Intentos de login (Devise ya incluye `Lockable` opcional pero no está activado)

Si el proyecto escala a producción, se recomienda implementar rate limiting via Rack::Attack o middleware similar.

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
- `.env` - Usa la lista de variables más arriba como plantilla
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
- ~~CSP (Content Security Policy)~~ — **COMENTADO** en `config/initializers/content_security_policy.rb`. No está activo. Pendiente de configuración para producción.
- CSRF protection — Activo via `protect_from_forgery with: :exception`
- Secure headers — Configurados por defecto en Rails 8

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Rails Guides](https://guides.rubyonrails.org/)
- [Devise Wiki](https://github.com/heartcombo/devise/wiki)
- [Pundit Documentation](https://github.com/varvet/pundit)
- [TailwindCSS](https://tailwindcss.com/docs)
- [Hotwire](https://hotwired.dev/)
- [Leaflet](https://leafletjs.com/)
- [Omniauth Google OAuth2](https://github.com/zquestz/omniauth-google-oauth2)

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

**Última actualización:** Junio 2026
