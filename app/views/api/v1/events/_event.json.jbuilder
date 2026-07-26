json.id event.id
json.name event.name
json.description event.description
json.start_date event.start_date
json.end_date event.end_date
json.status event.status

# Aforo y Disponibilidad
json.capacity do
  json.max_capacity event.max_capacity
  json.sold_tickets event.bookings.occupying_capacity.sum(:quantity)
  json.available_spots event.remaining_capacity
  json.is_sold_out event.sold_out?
end

# Ubicacion (Safe Data)
json.location do
  json.city event.city
  json.address event.address
  json.latitude event.latitude
  json.longitude event.longitude
end

# Categoria (Safe Data)
if event.category
  json.category do
    json.name event.category.name
    json.slug event.category.slug
  end
end

# Organizador (Safe Data - Solo el nombre)
if event.organizer
  json.organizer do
    json.name event.organizer.name
  end
end

# Tickets si estamos en la vista de detalle
if defined?(event.ticket_types) && event.ticket_types.any?
  json.ticket_types event.ticket_types do |ticket|
    json.name ticket.name
    json.price ticket.price
    json.currency event.currency
  end
end

# Imagen Principal
if event.primary_image.present?
  json.image_url event.primary_image.image_url
end
