# SPEC — Tickets Individuales y Check-in

> Propuesta para la sesión actual. Pendiente de aprobación antes de implementar.

---

## A) Modelo Ticket

### Estructura propuesta

```ruby
# frozen_string_literal: true

class Ticket < ApplicationRecord
  # ── Relations ──
  belongs_to :booking

  # ── Enums ──
  enum :status, {
    valid: 0,       # Activo, puede hacer check-in
    used: 1,        # Ya ingresó al evento
    cancelled: 2    # Cancelado (booking cancelado/expired)
  }

  # ── Validations ──
  validates :qr_code, presence: true, uniqueness: true

  # ── Scopes ──
  scope :valid, -> { where(status: :valid) }
  scope :used,  -> { where(status: :used) }

  # ── Callbacks ──
  before_create :generate_qr_code

  private

  def generate_qr_code
    self.qr_code ||= SecureRandom.uuid
  end
end
```

### Migración

| Campo | Tipo | Constraints |
|-------|------|-------------|
| `booking_id` | `bigint` | `NOT NULL`, FK → `bookings`, index único **NO** (un booking tiene N tickets) |
| `qr_code` | `string` | `NOT NULL`, unique index |
| `attendee_name` | `string` | nullable |
| `attendee_email` | `string` | nullable |
| `status` | `integer` | `NOT NULL`, default 0 |
| `checked_in_at` | `datetime` | nullable |
| `timestamps` | | |

### ¿Dónde se genera la creación de tickets?

**Decisión: `Tickets::GenerateService` (Service Object nuevo), invocado desde `Payments::ChargeService`.**

Justificación:
- El proyecto ya establece el patrón de Service Objects con `self.call` (ver `BookingService`, `ConfirmationCodeService`, `Payments::ChargeService`). Un callback en `Payment#approved?` rompería ese patrón y acoplaría lógica de generación de tickets al modelo.
- Si va dentro de `ChargeService` (dentro del `with_lock`), la generación de tickets es **atómica con el cobro**. No puede ocurrir que el pago se apruebe y los tickets no se generen.
- Un `after_create_commit` en Payment sería frágil: se dispararía aunque la transacción falle, y no estaría dentro del lock pesimista.

Flujo dentro de `ChargeService#call`:

```ruby
# Dentro de @booking.with_lock, después de @booking.update!(status: :confirmed)
Tickets::GenerateService.call(@booking) if payment.approved?
```

### Pregunta: ¿qué pasa si el pago falla y se reintenta? ¿Idempotencia?

**Respuesta:** `Tickets::GenerateService` debe ser **idempotente**. Antes de generar tickets, verifica si el booking ya tiene tickets:

```ruby
def call
  return if @booking.tickets.any?  # Idempotente: ya se generaron antes
  # ... generar N tickets ...
end
```

**Escenario concreto:**
1. Primer intento: payment declined → NO se genera nada. Booking sigue pending. ✓
2. Reintento: payment approved → se generan tickets. ✓
3. Webhook duplicado (approved) → `ChargeService` no se ejecuta (booking ya confirmed). ✓
4. Webhook refunded + re-charge → no aplica porque Booking ya tuvo payment unique. ✓

**Escenario borde:** Payment approved, tickets generados, pero `@booking.update!(status: :confirmed)` falla. La transacción dentro de `with_lock` se revierte COMPLETA — no se crearon tickets ni se confirmó el booking. Esto es correcto, la atomicidad está garantizada por `with_lock`.

### Relaciones a actualizar en Booking

```ruby
# Booking model — agregar:
has_many :tickets, dependent: :destroy
```

---

## B) Vista "Mis entradas" actualizada

### `app/views/bookings/show.html.erb`

Mantener el resumen de compra actual y **agregar debajo** una sección de tickets individuales:

```
┌─────────────────────────────────────────┐
│  ✅ ¡Compra confirmada!                  │
│  Resumen de compra (ya existe)           │
├─────────────────────────────────────────┤
│  Tus entradas                            │
│                                          │
│  ┌──────────┐  ┌──────────┐             │
│  │  QR #1   │  │  QR #2   │             │
│  │  VALID   │  │  VALID   │             │
│  │  Juan    │  │  María   │             │
│  └──────────┘  └──────────┘             │
│                                          │
│  ┌──────────┐                            │
│  │  QR #3   │                            │
│  │  USED    │  ← gris/opaco              │
│  │  Pedro   │                            │
│  └──────────┘                            │
└─────────────────────────────────────────┘
```

Cada ticket muestra:
- QR renderizado como imagen SVG (generado con `rqrcode`)
- `attendee_name` si tiene, o "Entrada #{n}" como fallback
- Status visual: `valid` = verde/borde sólido, `used` = gris/opaco

### Gem propuesta para QR: `rqrcode`

- Gema Ruby pura, genera QR sin servicios externos, sin internet.
- Permite output SVG (se renderiza inline, sin archivos).
- API: `RQRCode::QRCode.new(qr_code).as_svg`

### Pregunta: ¿dónde renderizar el QR, en el servidor (SVG inline) o en el cliente?

**Propuesta: SVG inline desde el servidor.** Ventajas:
- No requiere JavaScript.
- Funciona offline.
- Tamaño controlable vía CSS.
- El SVG se puede descargar/imprimir directamente.

---

## C) Endpoint y Vista de Check-in

### Rutas propuestas

```ruby
# Dentro del namespace :organizer, anidado bajo events:
namespace :organizer do
  resources :events do
    resource :check_in, only: [:show, :create], controller: "check_ins"
  end
end
```

Esto genera:
- `GET /organizer/events/:event_id/check_in` → formulario de check-in
- `POST /organizer/events/:event_id/check_in` → procesar QR

### Controlador

```ruby
module Organizer
  class CheckInsController < BaseController
    before_action :set_event

    def show
      # Renderiza vista con input de texto + canvas para cámara
    end

    def create
      @ticket = Ticket.find_by(qr_code: params[:qr_code])

      if @ticket.nil?
        return render json: { error: "Ticket no encontrado" }, status: :not_found
      end

      unless @ticket.valid?
        return render json: { error: "Ticket ya usado" }, status: :unprocessable_entity
      end

      unless @ticket.booking.event_id == @event.id
        return render json: { error: "Este ticket no pertenece a este evento" }, status: :forbidden
      end

      # Atomic check-in: update_all con WHERE status: :valid → protege contra doble check-in
      updated = Ticket.where(id: @ticket.id, status: :valid)
                      .update_all(status: :used, checked_in_at: Time.current)

      if updated == 1
        render json: { success: true, attendee: @ticket.attendee_name }
      else
        render json: { error: "Este ticket ya fue usado" }, status: :conflict
      end
    end

    private

    def set_event
      @event = current_user.admin? ? Event.find(params[:event_id])
                                    : current_user.organized_events.find(params[:event_id])
    end
  end
end
```

### Doble check-in concurrente

**Decisión: `update_all` con WHERE atómico en SQL.**

```ruby
Ticket.where(id: @ticket.id, status: :valid)
      .update_all(status: :used, checked_in_at: Time.current)
```

`update_all` genera una sola sentencia SQL:
```sql
UPDATE tickets SET status = 1, checked_in_at = NOW()
WHERE id = ? AND status = 0
```

PostgreSQL ejecuta esto atómicamente. Si dos organizadores escanean el mismo ticket:
1. Ambos ejecutan el UPDATE concurrentemente.
2. PostgreSQL serializa las escrituras a nivel de fila.
3. **Gana el primero:** `updated == 1`.
4. **Pierde el segundo:** `updated == 0` porque `status` ya no es `valid`.

Esto sigue el mismo patrón que `ExpireBookingsJob` (que usa `update_all` con WHERE atómico). No requiere `lock!` explícito porque la validación + actualización están en la misma sentencia SQL.

### Vista de check-in (show)

Dos modos de entrada:

1. **Cámara (principal):** Un `<video>` con `getUserMedia` + librería `html5-qrcode` vía CDN para escanear QR en tiempo real.
2. **Input manual (fallback):** Un `<input>` de texto para tipear/scannear el QR code manualmente.

### Gem/Lib JS propuesta: `html5-qrcode`

- Librería liviana vía CDN (no requiere build step, compatible con importmap).
- Usa `getUserMedia` para acceso a cámara.
- API simple: `Html5Qrcode.getCameras().then(...)`.
- Se carga en `<script>` desde CDN, no requiere npm/node.

### Pregunta: ¿response JSON o redirect con flash?

**Propuesta: respuesta JSON para la acción `create` (check-in con cámara) + fallback HTML para formulario manual.**

- La cámara opera vía JS → espera JSON.
- El input manual puede ser un form normal con redirect + flash.
- En la práctica: el `create` responde JSON siempre (el formulario manual también puede consumir JSON con un `data-turbo=false` o `remote: true`).

---

## D) Mailer de Confirmación de Compra

### Decisión: `TicketMailer` (nuevo mailer separado)

**Justificación:** `UserMailer` hoy maneja exclusivamente autenticación (`confirmation_code`). Agregar lógica de compras ahí mezclaría dos responsabilidades distintas. Un `TicketMailer` separado sigue SRP y es consistente con la separación de `Payments::ChargeService` vs `BookingService`.

### Cuándo se dispara

Dentro de `Tickets::GenerateService.call`, después de generar los tickets exitosamente:

```ruby
def call
  return if @booking.tickets.any?

  @booking.quantity.times do |i|
    @booking.tickets.create!(
      attendee_name: nil,  # Se puede llenar después
      attendee_email: nil
    )
  end

  TicketMailer.purchase_confirmation(@booking).deliver_later
end
```

¿Por qué desde el service y no desde ChargeService? Porque el mailer está asociado a la generación de tickets (el evento que le importa al usuario), no al cobro en sí. Si en el futuro se regeneran tickets sin cobrar (ej. admin corrigiendo), el mailer se dispara correctamente.

### Contenido del email

- Asunto: "Compra confirmada — #{@event.name}"
- Resumen: evento, tipo de entrada, cantidad, total pagado
- Link a "Ver mis entradas" (`booking_url(@booking)`)
- NO adjuntar QR todavía (iteración futura)

### Plantilla

Mantener el mismo estilo inline CSS del mailer existente (`user_mailer/confirmation_code.html.erb`).

---

## E) Políticas Pundit

### `TicketPolicy`

```ruby
class TicketPolicy < ApplicationPolicy
  def show?
    user.admin? || record.booking.user_id == user.id
  end

  # Sin update? ni destroy? — el único cambio de estado válido es vía
  # check-in, que tiene su propia autorización en el namespace :organizer
end
```

### Relación con check-in

El check-in NO usa Pundit para el ticket individual. Usa el `Organizer::BaseController` que ya verifica `organizer? || admin?`. Además, el controller verifica que el ticket pertenezca al evento del organizador (`@ticket.booking.event_id == @event.id`).

---

## Preguntas abiertas para decidir

1. **`rqrcode`** — ¿Aprobás usar `rqrcode` para generar QR como SVG inline? Alternativa: `qr-code` gem (más moderna, wrapper de `rqrcode`). Prefiero `rqrcode` por ser la más estable y la que usa menos dependencias.

2. **`html5-qrcode` vía CDN** — ¿Aprobás cargar la librería de escaneo QR desde CDN en el template de check-in (sin importmap, directo en `<script>`)? Es el mismo approach que usamos con Culqi JS en `payments/new.html.erb`.

3. **TicketMailer vs UserMailer** — ¿Estás de acuerdo con crear `TicketMailer` separado, o preferís agregar el método a `UserMailer`?

4. **`attendee_name` y `attendee_email`** — Hoy los propongo como nullable (se llenan después de la compra, opcional). ¿Querés que en esta iteración los dejemos siempre nil, o que el formulario de booking permita ingresar los nombres de cada asistente?

5. **Vista de check-in** — ¿Preferís HTML con Turbo (redirect+flash) o JSON API (para ser consumido por la cámara JS)? Mi propuesta es JSON para el POST y HTML para el GET.

6. **Scope de check-in** — El organizador puede hacer check-in de tickets de cualquier booking de sus eventos. ¿Querés restringir a bookings `confirmed` solamente, o incluimos también `pending` como válidos?

---

## Resumen de archivos a crear/modificar

### Nuevos
| Archivo | Propósito |
|---------|-----------|
| `db/migrate/*_create_tickets.rb` | Migración de tickets |
| `app/models/ticket.rb` | Modelo Ticket |
| `app/services/tickets/generate_service.rb` | Generación idempotente de tickets |
| `app/mailers/ticket_mailer.rb` | Mailer de confirmación |
| `app/views/ticket_mailer/purchase_confirmation.html.erb` | Plantilla del email |
| `app/controllers/organizer/check_ins_controller.rb` | Check-in |
| `app/views/organizer/check_ins/show.html.erb` | Formulario de check-in |
| `app/policies/ticket_policy.rb` | Policy Pundit |
| `spec/models/ticket_spec.rb` | Tests de modelo |
| `spec/services/tickets/generate_service_spec.rb` | Tests del generador |
| `spec/requests/organizer/check_ins_spec.rb` | Tests de check-in (incluye concurrencia) |
| `spec/mailers/ticket_mailer_spec.rb` | Tests del mailer |

### Modificados
| Archivo | Cambio |
|---------|--------|
| `app/models/booking.rb` | Agregar `has_many :tickets` |
| `app/services/payments/charge_service.rb` | Invocar `Tickets::GenerateService` y `TicketMailer` |
| `app/views/bookings/show.html.erb` | Listar tickets individuales con QR |
| `config/routes.rb` | Agregar ruta de check-in bajo organizer |
| `Gemfile` | Agregar `rqrcode` |

---

*Espero tu aprobación o ajustes antes de implementar.*
