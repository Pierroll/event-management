# Guía de Integración - SGE (Sistema de Gestión de Eventos)

## 1. Introducción

El Sistema de Gestión de Eventos (SGE) administra eventos culturales, musicales, y sociales en Perú. Actualmente opera como una aplicación monolítica HTML sin API pública. Esta guía documenta el diseño para exponer funcionalidades vía API REST JSON, permitiendo que socios estratégicos —turismo, hotelería, restaurantes, movilidad— integren el catálogo de eventos en sus plataformas.

El sistema actual gestiona eventos con geolocalización (geocoder gem), categorías, comentarios con rating, imágenes (Active Storage + legacy), roles de usuario (admin/organizer/registered_user), autenticación Google OAuth, y confirmación de email personalizada.

**Estado actual:** 100% HTML monolith. No existen endpoints JSON, serializadores, CORS, webhooks, ni sistema de bookings. Todo lo descrito aquí es una propuesta de implementación basada en la estructura de datos existente.

---

## 2. Autenticación y Seguridad

### 2.1 API Key

Toda solicitud a la API debe incluir el header:

```
X-Api-Key: pk_live_abc123def456
```

Las API Keys se asignan por partner (turismo, hoteles, restaurantes, movilidad) y se almacenan con `has_secure_token` o similar. Cada key tiene un scope asociado.

### 2.2 Scopes

| Scope | Acceso | Uso |
|-------|--------|-----|
| `public` | Solo eventos publicados, categorías activas, ciudades | Consultas generales, sin autenticación requerida |
| `partner` | Todo lo público + comentarios, disponibilidad, webhooks | Partners registrados |
| `admin` | Full access incluyendo datos internos | Solo uso interno SGE |

### 2.3 Rate Limiting

- **Límite:** 1000 requests por hora por partner
- **Response header:** `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- **Excedido:** HTTP 429 con `Retry-After`
- **Implementación:** Rack::Attack gem o middleware custom

### 2.4 HTTPS

Toda comunicación debe ser TLS 1.2+. Requests HTTP deben redirigir o ser rechazados.

### 2.5 HMAC para Webhooks

Los webhooks se firman con HMAC-SHA256 usando el secret del partner. Ver sección 8 para detalle.

---

## 3. Catálogo de APIs

| Endpoint | Existe Actualmente? | Método | Descripción | Scope | Exponer a Partners |
|----------|---------------------|--------|-------------|-------|-------------------|
| `/api/v1/events` | ✅ Sí (HTML) | `GET` | Listar eventos públicos con filtros | `public` | ✅ Sí |
| `/api/v1/events/:id` | ✅ Sí (HTML) | `GET` | Ver detalle de evento | `public` | ✅ Sí |
| `/api/v1/categories` | ✅ Sí (helper) | `GET` | Listar categorías activas | `public` | ✅ Sí |
| `/api/v1/events/:id/comments` | ✅ Sí (HTML) | `GET` | Listar comentarios de evento | `partner` | ✅ Sí |
| `/api/v1/cities` | ✅ Sí (helper) | `GET` | Listar ciudades con eventos publicados | `public` | ✅ Sí |
| `/api/v1/events/:id/availability` | ⚠️ Parcial | `GET` | Consultar disponibilidad (capacidad restante) | `partner` | ✅ Sí |
| `/api/v1/events/nearby` | ❌ No existe | `GET` | Búsqueda por radio geográfico | `public` | ✅ Sí |
| `/api/v1/events/calendar` | ❌ No existe | `GET` | Eventos por rango de fechas | `public` | ✅ Sí |
| `/api/v1/webhooks/register` | ❌ No existe | `POST` | Registrar webhook | `partner` | ✅ Sí |
| `/api/v1/webhooks/:id` | ❌ No existe | `DELETE` | Eliminar webhook | `partner` | ✅ Sí |
| `/api/v1/partners/stats` | ❌ No existe | `GET` | Estadísticas de consumo para partners | `partner` | ✅ Sí |

**Leyenda:**
- ✅ Sí (HTML) — La funcionalidad existe como vista HTML. Requiere wrapper API (controller JSON + serializer).
- ⚠️ Parcial — Los datos base existen (`max_capacity`) pero falta lógica de cálculo o modelo de bookings.
- ❌ No existe — Desarrollo nuevo completo.

---

## 4. Integración con Turismo

### 4.1 Búsqueda de eventos

Turismo necesita consultar eventos para recomendar a turistas según destino, fechas, y preferencias.

#### Filtros disponibles (todos existen actualmente)

| Filtro | Parámetro | Ejemplo | Implementación actual |
|--------|-----------|---------|-----------------------|
| Ciudad | `city` | `?city=Lima` | `Event.by_city` scope |
| Categoría | `category_id` | `?category_id=5` | `Event.by_category` scope |
| Texto libre | `query` | `?query=festival` | LIKE en `name` y `description` |
| Fecha inicio | `start_date` | `?start_date=2026-08-01` | `WHERE start_date >= ?` |
| Fecha fin | `end_date` | `?end_date=2026-08-31` | `WHERE start_date <= ?` |
| Precio mínimo | `price_min` | `?price_min=10` | `WHERE price >= ?` |
| Precio máximo | `price_max` | `?price_max=200` | `WHERE price <= ?` |

**Todos existen en `Events::SearchQuery`.** El wrapper API debe reusar esta misma query object.

### 4.2 Datos que Turismo podría proveer

- **SSO Identity** — Si turismo opera su propio login, podría delegarse autenticación vía OAuth2 (no implementado).
- **Preferencias del turista** — Categorías de interés, rango de precios, histórico de asistencias. Podrían enviarse como parámetros adicionales para personalizar resultados.

### 4.3 Payloads sugeridos

#### `GET /api/v1/events?city=Lima&category_id=5&start_date=2026-08-01&end_date=2026-08-31`

```json
{
  "data": [
    {
      "id": 1,
      "name": "Festival de Rock",
      "description": "El festival más grande de rock alternativo en la costa verde.",
      "category": {
        "id": 5,
        "name": "Música",
        "slug": "musica"
      },
      "city": "Lima",
      "address": "Av. La Marina 123, San Miguel",
      "latitude": -12.0748,
      "longitude": -77.0972,
      "start_date": "2026-08-15T20:00:00-05:00",
      "end_date": "2026-08-16T02:00:00-05:00",
      "price": "89.90",
      "currency": "PEN",
      "remaining_capacity": 150,
      "average_rating": 4.5,
      "status": "published",
      "primary_image_url": "https://sge.ejemplo.com/rails/active_storage/blobs/redirect/abc123/festival.jpg"
    }
  ],
  "meta": {
    "total": 1,
    "page": 1,
    "per_page": 20
  }
}
```

#### `GET /api/v1/events/:id`

```json
{
  "data": {
    "id": 1,
    "name": "Festival de Rock",
    "description": "El festival más grande de rock alternativo en la costa verde.",
    "category": {
      "id": 5,
      "name": "Música",
      "slug": "musica"
    },
    "city": "Lima",
    "address": "Av. La Marina 123, San Miguel",
    "latitude": -12.0748,
    "longitude": -77.0972,
    "start_date": "2026-08-15T20:00:00-05:00",
    "end_date": "2026-08-16T02:00:00-05:00",
    "price": "89.90",
    "currency": "PEN",
    "max_capacity": 500,
    "remaining_capacity": 150,
    "average_rating": 4.5,
    "status": "published",
    "images": [
      {
        "url": "https://sge.ejemplo.com/rails/active_storage/blobs/redirect/abc123/festival.jpg",
        "display_order": 1
      }
    ],
    "organizer": {
      "name": "Producciones Musicales SAC"
    }
  }
}
```

> **⚠️ Nota de seguridad:** `organizer` solo expone el nombre. NO se exponen `email`, `id` interno, ni datos personales del organizador.

#### `GET /api/v1/categories`

```json
{
  "data": [
    {
      "id": 1,
      "name": "Conciertos",
      "slug": "conciertos"
    },
    {
      "id": 5,
      "name": "Música",
      "slug": "musica"
    }
  ]
}
```

#### `GET /api/v1/cities`

```json
{
  "data": [
    "Lima",
    "Cusco",
    "Arequipa",
    "Trujillo"
  ]
}
```

#### `GET /api/v1/events/nearby?lat=-12.0464&lng=-77.0428&radius=10`

> **⚠️ No existe actualmente.** Requiere implementación con `geocoder` gem.

```json
{
  "data": [
    {
      "id": 1,
      "name": "Festival de Rock",
      "distance_km": 3.2,
      "latitude": -12.0748,
      "longitude": -77.0972,
      "city": "Lima",
      "address": "Av. La Marina 123, San Miguel",
      "start_date": "2026-08-15T20:00:00-05:00",
      "price": "89.90",
      "currency": "PEN",
      "remaining_capacity": 150
    }
  ]
}
```

#### `GET /api/v1/events/:id/comments`

```json
{
  "data": [
    {
      "id": 42,
      "rating": 5,
      "content": "Excelente evento, muy bien organizado.",
      "created_at": "2026-06-10T15:30:00-05:00"
    }
  ]
}
```

> **⚠️ Privacidad:** NO se expone el nombre del usuario ni su ID. Solo rating, contenido, y fecha.

#### `GET /api/v1/events/:id/availability`

> **⚠️ Parcialmente disponible.** `max_capacity` existe. `remaining_capacity` requiere cálculo: `max_capacity - bookings_count`. Sin sistema de bookings, se expone `max_capacity` y un flag estimado.

```json
{
  "data": {
    "event_id": 1,
    "max_capacity": 500,
    "remaining_capacity": 150,
    "availability_pct": 30,
    "status": "available"
  }
}
```

### 4.4 Cambios necesarios

1. **API wrapper controller** — `Api::V1::EventsController` con formato JSON, reusando `Events::SearchQuery` y `EventPolicy`
2. **Serializers** — Gem `alba` o `blueprinter` para controlar campos expuestos
3. **Geo-radius search** — Usar `geocoder` gem's `near` scope: `Event.near([lat, lng], radius)`
4. **Bookings system** — Modelo `Booking` para tracking real de capacidad (ver sección 10.3)
5. **CORS** — Configurar `rack-cors` si se requiere acceso desde navegador

---

## 5. Integración con Hoteles

### 5.1 Necesidades

Hoteles quieren recomendar eventos a sus huéspedes según:
- Ubicación del hotel (eventos cercanos)
- Fechas de estadía (check-in a check-out)
- Disponibilidad para grupos

### 5.2 Datos recibidos desde el hotel

```json
{
  "hotel_name": "Hotel Paracas",
  "latitude": -13.8382,
  "longitude": -76.2522,
  "check_in": "2026-09-10",
  "check_out": "2026-09-15",
  "guests": 4,
  "radius_km": 20,
  "preferences": {
    "category_ids": [1, 5],
    "price_max": 150
  }
}
```

### 5.3 Diseño recomendado

#### `POST /api/v1/hotels/events`

Reusa `Events::SearchQuery` con:
- `start_date` ← `check_in`
- `end_date` ← `check_out`
- `category_id` ← `preferences.category_ids` (filtro múltiple — requiere modificación menor)
- `price_max` ← `preferences.price_max`
- Geo-radius ← `near([latitude, longitude], radius_km)` (no existe, requiere implementación)

```json
{
  "data": [
    {
      "id": 3,
      "name": "Festival Gastronómico",
      "distance_km": 5.1,
      "start_date": "2026-09-12T11:00:00-05:00",
      "end_date": "2026-09-12T22:00:00-05:00",
      "price": "45.00",
      "currency": "PEN",
      "remaining_capacity": 200,
      "average_rating": 4.2,
      "category": "Gastronomía",
      "address": "Malecón 456, Paracas"
    }
  ],
  "meta": {
    "hotel": "Hotel Paracas",
    "check_in": "2026-09-10",
    "check_out": "2026-09-15",
    "total_events": 1
  }
}
```

### 5.4 Cambios requeridos

- **Geo-radius search** — Misma implementación que turismo (geocoder `near`)
- **Filtro múltiple de categorías** — Modificar `Events::SearchQuery` para aceptar array de `category_id`
- **Group availability** — Depende del sistema de bookings: verificar si `remaining_capacity >= guests`

---

## 6. Integración con Restaurantes

### 6.1 Necesidades

Restaurantes quieren sugerir eventos a comensales según:
- Cercanía al restaurante
- Horario compatible (before/after dinner)
- Tipo de evento

### 6.2 Datos recibidos desde el restaurante

```json
{
  "restaurant_name": "Central",
  "latitude": -12.1288,
  "longitude": -77.0362,
  "reservation_date": "2026-08-20",
  "reservation_time": "20:00",
  "radius_km": 3,
  "max_suggestions": 5,
  "preferences": {
    "category_ids": [1, 5, 7],
    "price_max": 200
  }
}
```

### 6.3 Diseño recomendado

#### `POST /api/v1/restaurants/suggestions`

Lógica de filtrado:
1. Buscar eventos publicados en el rango de fechas
2. Filtrar por proximidad (`near` con radio default 3km)
3. Filtrar por horario: eventos cuyo `start_date` esté dentro de `reservation_time +/- 3 horas`
4. Ordenar por cercanía y rating
5. Limitar a `max_suggestions` (default 5)

```json
{
  "data": [
    {
      "id": 7,
      "name": "Jazz en Vivo",
      "distance_km": 0.8,
      "start_date": "2026-08-20T21:00:00-05:00",
      "end_date": "2026-08-20T23:30:00-05:00",
      "price": "35.00",
      "currency": "PEN",
      "remaining_capacity": 80,
      "average_rating": 4.7,
      "category": "Música",
      "address": "Calle de las Letras 321, Lima"
    }
  ],
  "meta": {
    "restaurant": "Central",
    "reservation": "2026-08-20T20:00:00-05:00",
    "total_suggestions": 1
  }
}
```

### 6.4 Payload y respuesta

Respuesta con sugerencias ordenadas por relevancia (distancia + rating). Sin datos personales de comensales ni del restaurante (el restaurante se autentica como partner).

---

## 7. Integración con Movilidad y Transporte Turístico

### 7.1 Consideraciones

Empresas de movilidad (rent a car, transport turístico, agregadores como Uber/Taxi) necesitan:
- Ubicación de eventos (lat/lng, address) — ✅ **EXISTE**
- Horarios (start_date, end_date) — ✅ **EXISTE**
- Ciudad — ✅ **EXISTE**
- Categoría — ✅ **EXISTE**
- Demanda estimada (basada en capacidad restante) — ⚠️ **Parcial**

### 7.2 Necesidades específicas

| Dato | Disponible | Nota |
|------|-----------|-------|
| Latitud / Longitud | ✅ `event.latitude`, `event.longitude` | Geocoded automáticamente |
| Dirección | ✅ `event.address` | |
| Fecha inicio / fin | ✅ `event.start_date`, `event.end_date` | |
| Ciudad | ✅ `event.city` | |
| Categoría | ✅ `event.category_id` → `category.name` | |
| Capacidad restante | ⚠️ Parcial | `max_capacity` existe; falta `bookings` |
| Densidad de eventos por área | ❌ No existe | Requiere agrupación geográfica |

### 7.3 Datos que pueden proveer

- **Vehículos disponibles** — Flota actual, tipos (sedán, van, bus)
- **Tarifas** — Costo por km, tarifa plana a destinos
- **Puntos de recojo** — Paraderos, estaciones, lobby del hotel
- **Opciones de transporte** — Tour privado, shuttle compartido, under-demand

### 7.4 Diseño recomendado

#### `POST /api/v1/mobility/events`

Expone eventos con datos de demanda agregada. **Sin PII de asistentes.**

```json
{
  "data": [
    {
      "id": 1,
      "name": "Festival de Rock",
      "latitude": -12.0748,
      "longitude": -77.0972,
      "address": "Av. La Marina 123, San Miguel",
      "city": "Lima",
      "category": "Música",
      "start_date": "2026-08-15T20:00:00-05:00",
      "end_date": "2026-08-16T02:00:00-05:00",
      "max_capacity": 500,
      "remaining_capacity": 150,
      "capacity_utilization_pct": 70,
      "price": "89.90",
      "currency": "PEN"
    }
  ],
  "meta": {
    "time_slot": "2026-08-15T18:00:00-05:00/2026-08-16T04:00:00-05:00",
    "total_events": 1
  }
}
```

Parámetros de entrada:

```json
{
  "city": "Lima",
  "date": "2026-08-15",
  "time_slot": "18:00-04:00",
  "category_ids": [1, 5],
  "area": {
    "latitude": -12.0464,
    "longitude": -77.0428,
    "radius_km": 15
  }
}
```

---

## 8. Webhooks

### 8.1 Estado actual

**No existe sistema de webhooks.** Es desarrollo 100% nuevo. No hay modelo `Webhook`, no hay delivery, no hay HMAC.

### 8.2 Eventos disponibles

| Evento | Disparador | Estado actual |
|--------|-----------|---------------|
| `event.created` | Un evento es creado (cualquier estado) | ❌ Sin implementar |
| `event.updated` | El evento es modificado | ❌ Sin implementar |
| `event.cancelled` | `event.status` cambia a `canceled` | ❌ Sin implementar |
| `event.sold_out` | `remaining_capacity == 0` | ❌ Sin implementar (depende de bookings) |
| `event.capacity_threshold_reached` | `remaining_capacity <= max_capacity * 0.2` | ❌ Sin implementar (depende de bookings) |

### 8.3 Diseño técnico

#### Payload base

```json
{
  "event_id": 123,
  "event_name": "Festival de Rock",
  "status": "published",
  "start_date": "2026-08-15T20:00:00-05:00",
  "end_date": "2026-08-16T02:00:00-05:00",
  "city": "Lima",
  "category": "Música",
  "remaining_capacity": 150,
  "timestamp": "2026-06-16T10:30:00Z"
}
```

#### Headers

| Header | Valor | Descripción |
|--------|-------|-------------|
| `X-Webhook-Signature` | `sha256=...` | HMAC-SHA256 del body raw |
| `X-Webhook-Event` | `event.created` | Tipo de evento |
| `X-Webhook-Delivery` | `uuid` | ID único de entrega (idempotencia) |

#### Firma HMAC

El payload se firma con HMAC-SHA256 usando el `secret` del partner:

```
signature = HMAC-SHA256(secret, raw_request_body)
X-Webhook-Signature: sha256=#{signature}
```

**Verificación del lado del partner:**

```ruby
# Ejemplo en Ruby
expected = OpenSSL::HMAC.hexdigest(
  "SHA256", partner_secret, request.body.read
)
ActiveSupport::SecurityUtils.secure_compare(
  "sha256=#{expected}", request.headers["X-Webhook-Signature"]
)
```

#### Estrategia de reintentos

| Intento | Espera |
|---------|--------|
| 1 | 1 minuto |
| 2 | 5 minutos |
| 3 | 30 minutos |

- Si fallan los 3 intentos: el webhook se mueve a una **dead letter queue**
- Admin puede re-enviar manualmente desde el panel de administración
- Los deliveries se almacenan en un modelo `WebhookDelivery` con status, response code, y error message
- Se recomienda **idempotencia** vía `X-Webhook-Delivery` UUID para que el partner ignore duplicados

#### Registro de webhook

**`POST /api/v1/webhooks/register`** (scope: `partner`)

```json
{
  "url": "https://partner.ejemplo.com/webhooks/sge",
  "events": ["event.created", "event.updated", "event.cancelled"],
  "secret": "un-secret-compartido-64-chars-min"
}
```

Respuesta:

```json
{
  "data": {
    "id": 1,
    "url": "https://partner.ejemplo.com/webhooks/sge",
    "events": ["event.created", "event.updated", "event.cancelled"],
    "created_at": "2026-06-16T10:30:00Z"
  }
}
```

**`DELETE /api/v1/webhooks/:id`** (scope: `partner`)

- Solo el partner propietario puede eliminar su webhook
- Respuesta: `204 No Content`

---

## 9. Glosario de Datos Expuestos

| Campo | Tipo | Exponible? | Notas |
|-------|------|-----------|-------|
| `event.id` | `integer` | ✅ Sí | ID público del evento |
| `event.name` | `string` | ✅ Sí | |
| `event.description` | `text` | ✅ Sí | |
| `event.city` | `string` | ✅ Sí | |
| `event.address` | `string` | ✅ Sí | |
| `event.latitude` | `decimal` | ✅ Sí | |
| `event.longitude` | `decimal` | ✅ Sí | |
| `event.start_date` | `datetime` | ✅ Sí | |
| `event.end_date` | `datetime` | ✅ Sí | |
| `event.price` | `decimal` | ✅ Sí | |
| `event.currency` | `string` | ✅ Sí | Default `PEN` |
| `event.max_capacity` | `integer` | ✅ Sí | |
| `remaining_capacity` | `integer` | ✅ Sí | Calculado: `max_capacity - bookings_count` |
| `capacity_utilization_pct` | `integer` | ✅ Sí | Calculado: `((max - remaining) / max) * 100` |
| `event.status` | `string` | ✅ Sí | `draft`, `published`, `canceled`, `finished` |
| `event.average_rating` | `decimal` | ✅ Sí | 0.0 - 5.0 |
| `category.id` | `integer` | ✅ Sí | |
| `category.name` | `string` | ✅ Sí | |
| `category.slug` | `string` | ✅ Sí | |
| `event.organizer_name` | `string` | ✅ Sí | Solo nombre expuesto vía relación |
| `event.primary_image_url` | `string` | ✅ Sí | URL de Active Storage |
| `comment.rating` | `integer` | ✅ Sí | 1-5 |
| `comment.content` | `text` | ✅ Sí | |
| `comment.created_at` | `datetime` | ✅ Sí | |
| `user.id` | `integer` | ❌ NO | ID interno del usuario |
| `user.name` | `string` | ❌ NO | Dato personal |
| `user.email` | `string` | ❌ NO | Dato personal |
| `booking.user_id` | `integer` | ❌ NO | Datos privados de asistencia |
| `booking.user_name` | `string` | ❌ NO | Datos privados |
| `organizer.id` | `integer` | ❌ NO | ID interno |
| `organizer.email` | `string` | ❌ NO | Información privada |

---

## 10. Gap Analysis

### 10.1 Listo para liberar (solo requiere wrapper API)

| Endpoint | Archivos existentes que reusar | Complejidad |
|----------|-------------------------------|-------------|
| `GET /api/v1/events` | `EventsController#index`, `Events::SearchQuery`, `Event.published_only`, `EventPolicy::Scope` | Baja |
| `GET /api/v1/events/:id` | `EventsController#show`, `EventPolicy#show?` | Baja |
| `GET /api/v1/categories` | `Category.active` scope | Baja |
| `GET /api/v1/cities` | `Event.published_only.distinct.pluck(:city)` o similar | Baja |
| `GET /api/v1/events/calendar` | `Events::SearchQuery` con rango de fechas | Baja |

Estos endpoints requieren únicamente:
- `Api::V1::BaseController` con manejo de API Key y formateo JSON
- Serializer por modelo (alba, blueprinter, o `as_json` con `only`/`include`)
- Rutas anidadas en `config/routes.rb`

### 10.2 Cambios menores requeridos

| Endpoint | Cambio necesario | Complejidad |
|----------|-----------------|-------------|
| `GET /api/v1/events/:id/comments` | Scope de autenticación (solo partners pueden ver comentarios). No exponer datos de usuario. | Media |
| `GET /api/v1/events/:id/availability` | Requiere sistema de bookings o cálculo basado en `max_capacity` con flag estimado. | Media |

### 10.3 Desarrollo nuevo requerido

| Funcionalidad | Complejidad | Dependencias | Descripción |
|--------------|-------------|-------------|-------------|
| API Key authentication middleware | Media | `has_secure_token` o gem `jwt` | Middleware `Api::V1::Authenticate` que valida `X-Api-Key` y asigna scope |
| Rate limiting middleware | Media | `Rack::Attack` gem o Redis + contador | 1000 req/hora por partner, headers de rate limit |
| Geo-radius search (`/nearby`) | Media | Geocoder `near` scope (ya instalado) | `Event.near([lat, lng], radius)` con `select` de distancia |
| Bookings/reservations system | Alta | Nuevo modelo `Booking`, migraciones, validaciones de capacidad | Tracking real de asistentes por evento |
| Webhook system | Alta | `ActiveJob`, modelo `Webhook`, `WebhookDelivery`, HMAC lib, dead letter queue | Registro, delivery, retry, firma, administración |
| Filtro múltiple de categorías | Baja | Modificar `Events::SearchQuery` para aceptar array | `relation.where(category_id: ids)` si `ids` es array |

### 10.4 Tabla resumen de complejidad

| Funcionalidad | Complejidad | Dependencias | Orden sugerido |
|--------------|-------------|-------------|----------------|
| API wrapper (JSON) | Baja | `Api::BaseController`, serializer gem | 1 |
| Event calendar | Baja | Reusar `SearchQuery` con date range | 1 |
| Auth API Key | Media | `has_secure_token` o JWT | 2 |
| Rate limiting | Media | `Rack::Attack` gem | 3 |
| Geo-radius search | Media | Geocoder `near` scope (ya instalado) | 4 |
| Filtro múltiple categorías | Baja | Modificar `Events::SearchQuery` | 4 |
| Webhooks | Alta | ActiveJob, HMAC, modelo webhook | 5 |
| Bookings system | Alta | Nuevo modelo, migraciones, capacidad | 6 |

**Orden recomendado de implementación:**
1. **Fase 1** — API wrapper (eventos, categorías, ciudades, calendar) + API Key auth + rate limiting
2. **Fase 2** — Geo-radius search (abre turismo, hoteles, restaurantes) + comentarios API + filtro múltiple
3. **Fase 3** — Webhooks (notificaciones en tiempo real)
4. **Fase 4** — Bookings system (disponibilidad real, sold_out, capacity_threshold)
