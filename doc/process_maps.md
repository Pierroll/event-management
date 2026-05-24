# Mapas de Procesos y Matriz de Permisos - SGE

Este documento contiene los diagramas de procesos de negocio en Mermaid y la matriz detallada de permisos por rol para el **Sistema de Gestión de Eventos (SGE)**.

---

## 1. Mapas de Procesos (Mermaid)

### Proceso 1 — Autenticación y Acceso

```mermaid
flowchart TD
    A([Usuario ingresa al sistema]) --> B{¿Tiene sesión activa?}
    B -- Sí --> C{¿Qué rol tiene?}
    B -- No --> D[Vista pública / Visitante]
    D --> E{¿Quiere acceder a función protegida?}
    E -- No --> F[Navega como visitante]
    E -- Sí --> G[Redirige a Login]
    G --> H[Ingresa email y contraseña]
    H --> I{¿Credenciales válidas?}
    I -- No --> J[Muestra error] --> H
    I -- Sí --> K[Genera JWT con roles]
    K --> C
    C -- visitante --> F
    C -- registered_user --> L[Menú usuario registrado]
    C -- organizer --> M[Menú organizador]
    C -- admin --> N[Menú administrador]
```

---

### Proceso 2 — Registro de Usuario

```mermaid
flowchart TD
    A([Visitante hace clic en Registrarse]) --> B[Completa formulario\nnombre, email, contraseña]
    B --> C{¿Datos válidos?}
    C -- No --> D[Muestra errores de validación] --> B
    C -- Sí --> E{¿Email ya registrado?}
    E -- Sí --> F[Muestra error: email en uso] --> B
    E -- No --> G[Crea usuario en BD]
    G --> H[Asigna rol: registered_user]
    H --> I[Genera JWT]
    I --> J([Redirige al listado de eventos])
```

---

### Proceso 3 — Exploración y Búsqueda de Eventos

```mermaid
flowchart TD
    A([Usuario accede a Explorar eventos]) --> B[Carga listado paginado\nstatus = published]
    B --> C{¿Aplica filtros?}
    C -- No --> D[Muestra grid de cards]
    C -- Sí --> E{Tipo de filtro}
    E -- Categoría --> F[Filtra por category_id]
    E -- Fecha --> G[Filtra por start_date]
    E -- Ciudad --> H[Filtra por city]
    E -- Precio --> I[Filtra por price]
    E -- Texto --> J[Búsqueda en name y description]
    E -- Ubicación --> K[Búsqueda por lat/lng/radio]
    F & G & H & I & J & K --> L[Combina filtros activos]
    L --> D
    D --> M{¿Usuario hace clic en evento?}
    M -- Sí --> N([Ver detalle del evento])
    M -- No --> O{¿Cambia a vista mapa?}
    O -- Sí --> P[Muestra marcadores en mapa]
    P --> Q{¿Clic en marcador?}
    Q -- Sí --> N
    Q -- No --> P
```

---

### Proceso 4 — Ver Detalle y Comentar Evento

```mermaid
flowchart TD
    A([Usuario abre detalle de evento]) --> B[Carga datos del evento\nimágenes, valoración, comentarios]
    B --> C{¿Usuario autenticado?}
    C -- No --> D[Muestra botón Iniciar sesión\npara comentar]
    C -- Sí --> E{¿Ya comentó este evento?}
    E -- Sí --> F[Muestra su comentario\ncon opciones editar / eliminar]
    E -- No --> G[Muestra formulario de comentario]
    G --> H[Escribe comentario y selecciona estrellas]
    H --> I{¿Datos válidos?}
    I -- No --> J[Muestra error de validación] --> H
    I -- Sí --> K[Guarda comentario en BD]
    K --> L[Trigger recalcula average_rating]
    L --> M[Actualiza valoración en pantalla]
    F --> N{¿Edita comentario?}
    N -- Sí --> H
    N -- No --> O{¿Elimina comentario?}
    O -- Sí --> P[Elimina de BD]
    P --> L
```

---

### Proceso 5 — Gestión de Eventos (Organizador)

```mermaid
flowchart TD
    A([Organizador accede a Mis eventos]) --> B[Lista sus eventos con estado]
    B --> C{¿Qué acción elige?}
    C -- Crear --> D[Completa formulario de evento]
    D --> E{¿Datos válidos?}
    E -- No --> F[Muestra errores] --> D
    E -- Sí --> G[Guarda evento con status = draft]
    G --> H{¿Publica ahora?}
    H -- Sí --> I[Cambia status a published]
    H -- No --> B
    C -- Editar --> J{¿Evento en estado finished?}
    J -- Sí --> K[Muestra error: no editable\nTrigger BD lo bloquea]
    J -- No --> L[Carga formulario con datos actuales]
    L --> M[Guarda cambios]
    M --> B
    C -- Cancelar --> N[Confirma cancelación]
    N --> O[Cambia status a canceled]
    O --> B
    C -- Publicar --> I
    I --> B
```

---

### Proceso 6 — Panel de Administración

```mermaid
flowchart TD
    A([Admin accede al panel]) --> B[Dashboard:\ntotal eventos, usuarios, comentarios]
    B --> C{¿Qué módulo gestiona?}
    C -- Eventos --> D[Lista todos los eventos]
    D --> E{¿Acción sobre evento?}
    E -- Cambiar estado --> F[Actualiza status en BD]
    E -- Eliminar --> G[Elimina evento y sus imágenes]
    F & G --> D
    C -- Usuarios --> H[Lista todos los usuarios]
    H --> I{¿Acción sobre usuario?}
    I -- Activar/Desactivar --> J[Cambia campo active]
    I -- Asignar rol --> K[Inserta en user_roles\ncon assigned_by_id = admin]
    J & K --> H
    C -- Categorías --> L[Lista categorías]
    L --> M{¿Acción?}
    M -- Crear --> N[Nuevo registro en categories]
    M -- Editar --> O[Actualiza nombre y slug]
    M -- Activar/Desactivar --> P[Cambia campo active]
    N & O & P --> L
    C -- Comentarios --> Q[Lista comentarios reportados]
    Q --> R{¿Elimina?}
    R -- Sí --> S[Elimina comentario]
    S --> T[Trigger recalcula average_rating]
    T --> Q
    C -- Reportes --> U[Muestra estadísticas\npor evento y globales]
```

---

## 2. Matriz de Permisos por Rol

**Convención:** ✓ acceso completo · ◐ acceso parcial · ✗ sin acceso

### Módulo 1 — Eventos públicos
*Listado, búsqueda, filtros, mapa, detalle*

| Acción | Visitante | Usuario registrado | Organizador | Admin |
|---|---|---|---|---|
| Ver listado de eventos | ✓ | ✓ | ✓ | ✓ |
| Buscar y filtrar eventos | ✓ | ✓ | ✓ | ✓ |
| Ver mapa de eventos | ✓ | ✓ | ✓ | ✓ |
| Ver detalle de evento | ✓ | ✓ | ✓ | ✓ |
| Ver galería de imágenes | ✓ | ✓ | ✓ | ✓ |

### Módulo 2 — Comentarios y valoraciones
*Opiniones y estrellas por evento*

| Acción | Visitante | Usuario registrado | Organizador | Admin |
|---|---|---|---|---|
| Ver comentarios | ✓ | ✓ | ✓ | ✓ |
| Publicar comentario | ✗ | ✓ | ✓ | ✓ |
| Editar su comentario | ✗ | ✓ | ✓ | ✓ |
| Eliminar su comentario | ✗ | ✓ | ✓ | ✓ |
| Eliminar cualquier comentario | ✗ | ✗ | ✗ | ✓ |

### Módulo 3 — Gestión de mis eventos
*Panel del organizador*

| Acción | Visitante | Usuario registrado | Organizador | Admin |
|---|---|---|---|---|
| Ver panel "mis eventos" | ✗ | ✗ | ✓ | ✓ |
| Crear evento | ✗ | ✗ | ✓ | ✓ |
| Editar su evento | ✗ | ✗ | ✓ | ✓ |
| Publicar su evento | ✗ | ✗ | ✓ | ✓ |
| Cancelar su evento | ✗ | ✗ | ✓ | ✓ |
| Subir imágenes | ✗ | ✗ | ✓ | ✓ |
| Editar evento ajeno | ✗ | ✗ | ✗ | ✓ |
| Eliminar evento ajeno | ✗ | ✗ | ✗ | ✓ |

### Módulo 4 — Categorías
*Catálogo de tipos de evento*

| Acción | Visitante | Usuario registrado | Organizador | Admin |
|---|---|---|---|---|
| Ver categorías | ✓ | ✓ | ✓ | ✓ |
| Crear categoría | ✗ | ✗ | ✗ | ✓ |
| Editar categoría | ✗ | ✗ | ✗ | ✓ |
| Activar / desactivar | ✗ | ✗ | ✗ | ✓ |

### Módulo 5 — Usuarios y roles
*Gestión de cuentas*

| Acción | Visitante | Usuario registrado | Organizador | Admin |
|---|---|---|---|---|
| Registrarse | ✓ | ✗ | ✗ | ✗ |
| Iniciar sesión | ✓ | ✓ | ✓ | ✓ |
| Ver su perfil | ✗ | ✓ | ✓ | ✓ |
| Editar su perfil | ✗ | ✓ | ✓ | ✓ |
| Ver todos los usuarios | ✗ | ✗ | ✗ | ✓ |
| Activar / desactivar usuario | ✗ | ✗ | ✗ | ✓ |
| Asignar roles | ✗ | ✗ | ✗ | ✓ |

### Módulo 6 — Panel de administración
*Dashboard y moderación*

| Acción | Visitante | Usuario registrado | Organizador | Admin |
|---|---|---|---|---|
| Ver dashboard general | ✗ | ✗ | ✗ | ✓ |
| Ver todos los eventos | ✗ | ✗ | ✗ | ✓ |
| Cambiar estado de cualquier evento | ✗ | ✗ | ✗ | ✓ |
| Moderar comentarios | ✗ | ✗ | ✗ | ✓ |

### Módulo 7 — Reportes y estadísticas
*Métricas del sistema*

| Acción | Visitante | Usuario registrado | Organizador | Admin |
|---|---|---|---|---|
| Ver estadísticas de sus eventos | ✗ | ✗ | ✓ | ✓ |
| Ver estadísticas globales | ✗ | ✗ | ✗ | ✓ |

---

## 3. Navegación y Menú Dinámico

* **Visitante**:
  `Inicio | Explorar eventos | Mapa | [Iniciar sesión] [Registrarse]`
* **Usuario registrado**:
  `Inicio | Explorar eventos | Mapa | Mi perfil | Mis comentarios | [Cerrar sesión]`
* **Organizador**:
  `Inicio | Explorar eventos | Mapa | Mis eventos | Mi perfil | [Cerrar sesión]`
* **Administrador**:
  `Inicio | Explorar eventos | Panel admin (Dashboard | Eventos | Usuarios | Categorías | Reportes) | [Cerrar sesión]`
