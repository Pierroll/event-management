# Plan de Migración: `frontend/` → Rails + Hotwire (Turbo + Stimulus)

## Problema Detectado

El proyecto tiene una carpeta [`frontend/`](../frontend/) que implementa una arquitectura SPA separada (Axios + JWT + Store propio), pero:
- No existen rutas `/api` en [`config/routes.rb`](../config/routes.rb)
- No existen vistas ERB para ningún controlador (solo el layout)
- Los controladores Rails ya están listos para renderizar HTML
- El stack (Rails 8 + Hotwire + Tailwind + Importmap) ya cubre todo el frontend sin Node.js

## Estrategia

Migrar toda la lógica del frontend JS a **Stimulus controllers** y crear **vistas ERB** usando **Turbo** para navegación fluida. Eliminar la carpeta `frontend/` al final.

---

## FASE 1: Configurar estructura Stimulus + Importmap

### 1.1 Crear directorios Stimulus

```
app/javascript/
├── controllers/
│   ├── index.js          (registro automático de controllers)
│   ├── application.js    (config inicial)
│   ├── explore_controller.js
│   ├── event_detail_controller.js
│   ├── event_form_controller.js
│   ├── organizer_dashboard_controller.js
│   └── flash_controller.js
├── lib/
│   └── store.js          (si es necesario, opcional)
```

### 1.2 Configurar `app/javascript/application.js`

Punto de entrada JS que importa Stimulus y registra los controllers.

### 1.3 Actualizar `config/importmap.rb`

Añadir mapeos para:
- `@hotwired/stimulus` (ya incluido por defecto en Rails 8)
- `leaflet` (para mapas)
- `leaflet-css` (vía CDN)

### 1.4 Actualizar layout

En [`app/views/layouts/application.html.erb`](../app/views/layouts/application.html.erb):
- Agregar `<%= javascript_importmap_tags %>`
- Agregar `<%= stimulus_include_tags %>`
- Mejorar estructura HTML (nav, flash messages, yield, footer)

---

## FASE 2: Vistas ERB públicas (Home, Events, Profiles)

### 2.1 `app/views/home/index.html.erb`

Landing page con:
- Hero section con llamado a la acción
- Grid de 6 eventos próximos (`@upcoming_events`)
- Listado de categorías activas (`@categories`)
- Enlaces a `/events` (explorar)

### 2.2 `app/views/events/_event_card.html.erb`

Partial reutilizable para mostrar un evento como card:
- Imagen principal (primera `event_image`)
- Nombre, ciudad, fecha, precio
- Rating promedio
- Badge de estado

### 2.3 `app/views/events/_filters.html.erb`

Partial de filtros:
- Búsqueda por texto (query)
- Select de categoría
- Select de ciudad
- Rango de fechas
- Rango de precios
- Botón de geolocalización (Stimulus)

### 2.4 `app/views/events/index.html.erb`

Página de exploración (data-controller="explore"):
- Renderiza `_filters.html.erb`
- Grid de eventos con paginación (Kaminari)
- Mapa Leaflet (toggle vista lista/mapa)

### 2.5 `app/views/events/show.html.erb`

Detalle del evento (data-controller="event-detail"):
- Imágenes del evento (galería/carousel)
- Información detallada (nombre, descripción, fecha, lugar, precio, categoría)
- Mapa estático con ubicación
- Sección de comentarios con formulario (Turbo)
- Rating con estrellas (Stimulus)

### 2.6 `app/views/profiles/show.html.erb`

Perfil del usuario autenticado:
- Datos personales (nombre, email)
- Enlace a editar perfil

### 2.7 `app/views/profiles/edit.html.erb`

Formulario de edición de perfil:
- Campos: nombre, email
- Validaciones con errores inline

---

## FASE 3: Vistas ERB Organizer

### 3.1 `app/views/organizer/events/index.html.erb`

Dashboard del organizador (data-controller="organizer-dashboard"):
- Tabla/listado de eventos propios con paginación
- Columnas: nombre, estado, fecha, categoría
- Acciones inline: Publicar / Cancelar (Turbo Streams)
- Enlace "Crear nuevo evento"

### 3.2 `app/views/organizer/events/show.html.erb`

Detalle del evento (vista organizador):
- Toda la info del evento
- Enlaces: Editar, Eliminar, Volver

### 3.3 `app/views/organizer/events/new.html.erb`

Formulario de creación (data-controller="event-form"):
- Campos: nombre, descripción, ciudad, dirección, fecha inicio, fecha fin, precio, moneda, capacidad, categoría, estado
- Drag & drop para imágenes (Stimulus)
- Validación client-side
- Preview de imágenes antes de subir

### 3.4 `app/views/organizer/events/edit.html.erb`

Formulario de edición (reusa partial del form):
- Mismos campos que create
- Imágenes existentes con opción de eliminar
- Carga de nuevas imágenes

### 3.5 Partial `app/views/organizer/events/_form.html.erb`

Formulario compartido entre new y edit.

---

## FASE 4: Vistas ERB Admin

### 4.1 `app/views/admin/dashboard/index.html.erb`

Dashboard admin:
- Cards con métricas: usuarios totales, eventos totales, eventos publicados, comentarios totales
- Enlaces rápidos a gestión de usuarios, eventos, categorías

### 4.2 `app/views/admin/users/index.html.erb`

Listado de usuarios con paginación:
- Tabla: nombre, email, roles, activo, fecha registro
- Acciones: Ver, Editar

### 4.3 `app/views/admin/users/show.html.erb`

Detalle de usuario:
- Información completa
- Roles asignados
- Eventos organizados (si aplica)

### 4.4 `app/views/admin/users/edit.html.erb`

Editar usuario:
- Campos: nombre, email, activo
- Checkboxes para roles
- Botón guardar

### 4.5 `app/views/admin/events/index.html.erb`

Listado global de eventos (todos los estados):
- Filtros por estado
- Tabla con paginación
- Acciones: Ver, Cambiar estado

### 4.6 `app/views/admin/events/show.html.erb`

Detalle admin de evento:
- Toda la info + organizador
- Formulario para cambiar estado
- Estadísticas (comentarios, rating)

### 4.7 `app/views/admin/categories/index.html.erb`

Listado de categorías:
- Tabla: nombre, slug, descripción, activo
- Acciones: Ver, Editar, Eliminar
- Botón "Nueva categoría"

### 4.8 `app/views/admin/categories/new.html.erb`

### 4.9 `app/views/admin/categories/edit.html.erb`

### 4.10 `app/views/admin/categories/_form.html.erb`

---

## FASE 5: Stimulus Controllers

### 5.1 `explore_controller.js`

**Origen**: [`ExploreController.js`](../frontend/src/controllers/ExploreController.js)

**Funcionalidad**:
- `connect()`: Carga inicial de eventos si hay filtros en URL
- `search(event)`: Input de texto con debounce (400ms)
- `filterCategory(event)`: Select de categoría
- `filterCity(event)`: Select/filtro de ciudad
- `filterDate(event)`: Rango de fechas
- `activateProximity(event)`: Geolocalización → lat/lng/radius
- `toggleView(event)`: Cambiar entre grid list y mapa
- Mapa Leaflet con marcadores

**Targets**: `form`, `resultsGrid`, `mapContainer`, `searchInput`, `categorySelect`, `cityInput`, `dateStart`, `dateEnd`, `priceMin`, `priceMax`

**Valores**: `debounceMs` (400)

### 5.2 `event_detail_controller.js`

**Origen**: [`EventDetailController.js`](../frontend/src/controllers/EventDetailController.js)

**Funcionalidad**:
- `connect()`: Configurar estrellas de rating
- `rate(event)`: Manejar clic en estrellas (1-5)
- `highlightStars(event)`: Hover highlight en estrellas
- `submitComment(event)`: Enviar comentario vía Turbo (no AJAX)
- Manejo de optimistic UI (opcional con Turbo)

**Targets**: `starsContainer`, `ratingInput`, `commentForm`

### 5.3 `event_form_controller.js`

**Origen**: [`EventFormController.js`](../frontend/src/controllers/EventFormController.js)

**Funcionalidad**:
- `connect()`: Inicializar drag & drop zone
- `dragOver(event)`, `dragLeave(event)`: Efectos visuales
- `drop(event)`: Capturar archivos arrastrados
- `fileChange(event)`: Capturar desde input file
- `removeFile(event)`: Eliminar preview
- `validate(event)`: Validación client-side antes de submit
- `preventSubmit(event)`: Bloquear submit si hay errores

**Targets**: `dropzone`, `fileInput`, `previewContainer`, `errorContainer`

### 5.4 `organizer_dashboard_controller.js`

**Origen**: [`OrganizerDashboardController.js`](../frontend/src/controllers/OrganizerDashboardController.js)

**Funcionalidad**:
- `connect()`: Setup inicial
- `publish(event)`: Publicar evento (Turbo Stream)
- `cancel(event)`: Cancelar evento con confirmación

**Targets**: `eventRow`

**Valores**: `eventId`, `status`

### 5.5 `flash_controller.js`

Nuevo:
- `connect()`: Auto-esconder flash messages después de 5 segundos
- `close(event)`: Cerrar manualmente

**Targets**: `message`

---

## FASE 6: Leaflet via Importmap

### 6.1 Actualizar `config/importmap.rb`

```ruby
pin "leaflet", to: "https://unpkg.com/leaflet@1.9.4/dist/leaflet-src.js"
```

### 6.2 Agregar CSS de Leaflet

En [`app/assets/tailwind/application.css`](../app/assets/tailwind/application.css) o vía CDN en layout.

---

## FASE 7: Limpieza

### 7.1 Eliminar carpeta `frontend/`

```
rm -rf frontend/
```

### 7.2 Verificar que no haya referencias a `frontend/` en ningún archivo

Buscar imports, referencias a `api/client.js`, `Store`, etc.

---

## FASE 8: Verificación

### 8.1 Rutas a probar

| Ruta | Método | Controller#Action | Vista ERB |
|------|--------|-------------------|-----------|
| `/` | GET | `home#index` | ✅ |
| `/events` | GET | `events#index` | ✅ |
| `/events/:id` | GET | `events#show` | ✅ |
| `/events/:id/comments` | POST | `comments#create` | ✅ (redirect) |
| `/profile` | GET | `profiles#show` | ✅ |
| `/organizer/events` | GET | `organizer/events#index` | ✅ |
| `/organizer/events/new` | GET | `organizer/events#new` | ✅ |
| `/admin/dashboard` | GET | `admin/dashboard#index` | ✅ |
| `/admin/users` | GET | `admin/users#index` | ✅ |
| `/admin/categories` | GET | `admin/categories#index` | ✅ |

### 8.2 Verificar funcionalidad

- [ ] Autenticación (registro, login, logout) funciona con Devise + Turbo
- [ ] Exploración de eventos con filtros funciona
- [ ] Mapa Leaflet se renderiza correctamente
- [ ] Rating con estrellas en detalle del evento
- [ ] Comentarios se crean y muestran correctamente
- [ ] Organizador puede crear/editar/publicar/cancelar eventos
- [ ] Admin puede gestionar usuarios, eventos y categorías
- [ ] Paginación funciona en todas las vistas
- [ ] Flash messages se muestran y auto-esconden

---

## Mapa de Migración: Código JS → Stimulus

| Archivo JS (frontend/) | Destino Stimulus | Líneas relevantes |
|------------------------|-----------------|-------------------|
| `ExploreController.js` | `explore_controller.js` | Filtros, mapa, geolocalización |
| `EventDetailController.js` | `event_detail_controller.js` | Estrellas, comentarios |
| `EventFormController.js` | `event_form_controller.js` | Drag & drop, validación |
| `OrganizerDashboardController.js` | `organizer_dashboard_controller.js` | Publicar/cancelar |
| `Store.js` + `activeStores.js` | ❌ Eliminar | Reemplazado por Turbo + DOM |
| `api/client.js` | ❌ Eliminar | Reemplazado por formularios HTML |
| `services/auth.js` | ❌ Eliminar | Reemplazado por Devise + Turbo |
| `services/events.js` | ❌ Eliminar | Reemplazado por HTML + Turbo |
| `services/comments.js` | ❌ Eliminar | Reemplazado por formularios |
| `services/organizer.js` | ❌ Eliminar | Reemplazado por HTML + Turbo |