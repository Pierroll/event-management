# Este archivo de semillas ha sido refactorizado para ser completamente idempotente.
# Esto significa que puede ejecutarse múltiples veces sin duplicar datos existentes.
#
# ¿Por qué es importante la idempotencia?
# En entornos de producción como Render, los deploys pueden ejecutar las tareas de `db:seed`
# de forma automática. Si las semillas no son idempotentes, cada deploy podría:
# 1. Crear roles, categorías, usuarios o eventos duplicados.
# 2. Romper validaciones de unicidad en la base de datos.
# 3. Consumir espacio innecesariamente con datos redundantes.
#
# Al usar `find_or_create_by!`, `find_or_initialize_by` y verificaciones de existencia,
# garantizamos que los registros solo se creen si no existen, y sus atributos se actualicen
# o se dejen intactos según la lógica definida, sin causar duplicaciones.

puts "Cargando roles por defecto..."
roles = %w[admin organizer registered_user].map do |role_name|
  # Usamos find_or_create_by! para asegurar que los roles solo se creen si no existen.
  # Si existen, se recuperan; si no, se crean con la descripción.
  Role.find_or_create_by!(name: role_name) do |r|
    r.description = "Rol de #{role_name.humanize}"
  end
end

puts "Cargando categorías iniciales..."
categories_data = [
  { name: "Tecnología", slug: "tecnologia", description: "Eventos, hackathons y conferencias de tecnología" },
  { name: "Música", slug: "musica", description: "Conciertos, festivales y shows en vivo" },
  { name: "Deportes", slug: "deportes", description: "Torneos, partidos y actividades deportivas" },
  { name: "Arte y Cultura", slug: "arte-y-cultura", description: "Exposiciones, teatro y eventos culturales" },
  { name: "Gastronomía", slug: "gastronomia", description: "Ferias de comida, catas de vino y cenas" }
]

categories = categories_data.map do |cat_data|
  # Usamos find_or_create_by! para asegurar que las categorías solo se creen si no existen
  # (basado en el slug único). Si existen, se recuperan; si no, se crean con los datos.
  Category.find_or_create_by!(slug: cat_data[:slug]) do |c|
    c.name = cat_data[:name]
    c.description = cat_data[:description]
    c.active = true
  end
end

puts "Creando/Actualizando usuarios iniciales..."

# Helper para asignar roles de forma idempotente a un usuario
def assign_role_idempotently(user, role_name)
  role = Role.find_by(name: role_name)
  if role && !user.roles.include?(role)
    user.roles << role
    puts "  - Asignado rol '#{role_name}' a #{user.email}"
  end
end

# Admin (eventos.com)
admin_user = User.find_or_initialize_by(email: "admin@eventos.com")
if admin_user.new_record?
  admin_user.name = "Admin Principal"
  admin_user.password = "admin123"
  admin_user.password_confirmation = "admin123"
  admin_user.active = true
  admin_user.confirmed_at = Time.current
  admin_user.selected_role = "admin"
  admin_user.save!
  puts "Admin creado (admin@eventos.com / admin123)"
else
  if admin_user.name != "Admin Principal" || !admin_user.active
    admin_user.update!(name: "Admin Principal", active: true)
    puts "Admin actualizado (admin@eventos.com)"
  else
    puts "Admin ya existe y está actualizado (admin@eventos.com)"
  end
end
assign_role_idempotently(admin_user, "admin")

# Admin (admin.com) — el que usás para probar
admin_admin = User.find_or_initialize_by(email: "admin@admin.com")
if admin_admin.new_record?
  admin_admin.name = "Admin Local"
  admin_admin.password = "admin123"
  admin_admin.password_confirmation = "admin123"
  admin_admin.active = true
  admin_admin.confirmed_at = Time.current
  admin_admin.selected_role = "admin"
  admin_admin.save!
  puts "Admin creado (admin@admin.com / admin123)"
else
  puts "Admin ya existe (admin@admin.com)"
end
assign_role_idempotently(admin_admin, "admin")


# Organizer
organizer_user = User.find_or_initialize_by(email: "organizer@eventos.com")
if organizer_user.new_record?
  organizer_user.name = "Organizador Oficial"
  organizer_user.password = "organizer123"
  organizer_user.password_confirmation = "organizer123"
  organizer_user.active = true
  organizer_user.confirmed_at = Time.current
  organizer_user.selected_role = "organizer"
  organizer_user.save!
  puts "Organizador creado (organizer@eventos.com / organizer123)"
else
  if organizer_user.name != "Organizador Oficial" || !organizer_user.active
    organizer_user.update!(name: "Organizador Oficial", active: true)
    puts "Organizador actualizado (organizer@eventos.com)"
  else
    puts "Organizador ya existe y está actualizado (organizer@eventos.com)"
  end
end
assign_role_idempotently(organizer_user, "organizer")

# Registered User
registered_user = User.find_or_initialize_by(email: "user@eventos.com")
if registered_user.new_record?
  registered_user.name = "Juan Pérez"
  registered_user.password = "user123"
  registered_user.password_confirmation = "user123"
  registered_user.active = true
  registered_user.confirmed_at = Time.current
  registered_user.selected_role = "registered_user"
  registered_user.save!
  puts "Usuario común creado (user@eventos.com / user123)"
else
  if registered_user.name != "Juan Pérez" || !registered_user.active
    registered_user.update!(name: "Juan Pérez", active: true)
    puts "Usuario común actualizado (user@eventos.com)"
  else
    puts "Usuario común ya existe y está actualizado (user@eventos.com)"
  end
end
assign_role_idempotently(registered_user, "registered_user")

# Extra users for commenting
# Mantenemos una lista de usuarios (incluyendo el registered_user principal) para los comentarios
users = [registered_user]
5.times do |i|
  u = User.find_or_initialize_by(email: "user#{i}@eventos.com")
  if u.new_record?
    u.name = "Usuario Falso #{i}"
    u.password = "password123"
    u.password_confirmation = "password123"
    u.active = true
    u.confirmed_at = Time.current
    u.selected_role = "registered_user"
    u.save!
    puts "Usuario extra creado: #{u.email}"
  else
    # Opcional: Actualizar atributos para usuarios extra si cambian en el seed
    if u.name != "Usuario Falso #{i}" || !u.active
      u.update!(name: "Usuario Falso #{i}", active: true)
      puts "Usuario extra actualizado: #{u.email}"
    else
      puts "Usuario extra ya existe y está actualizado: #{u.email}"
    end
  end
  assign_role_idempotently(u, "registered_user")
  users << u unless users.include?(u) # Asegura que no se dupliquen en la lista si ya existían
end


puts "Creando eventos y fotos de prueba (si no existen)..."
event_data = [
  {
    name: "Rails World 2026",
    description: "La conferencia mundial más grande de Ruby on Rails, reuniendo a creadores y profesionales de todo el mundo.",
    city: "Lima",
    address: "Centro de Convenciones de Lima",
    start_date: 2.months.from_now,
    end_date: 2.months.from_now + 2.days,
    price: 350.00,
    currency: "USD",
    max_capacity: 500,
    status: :published,
    category: Category.find_by(slug: "tecnologia"),
    organizer: organizer_user,
    images: ["https://picsum.photos/800/600?random=1", "https://picsum.photos/800/600?random=2"]
  },
  {
    name: "Festival de Rock Latino",
    description: "Los mejores exponentes del rock en español en un solo escenario durante 12 horas seguidas.",
    city: "Arequipa",
    address: "Jardín de la Cerveza",
    start_date: 1.month.from_now,
    end_date: 1.month.from_now + 8.hours,
    price: 120.00,
    currency: "PEN",
    max_capacity: 10000,
    status: :published,
    category: Category.find_by(slug: "musica"),
    organizer: organizer_user,
    images: ["https://picsum.photos/800/600?random=3"]
  },
  {
    name: "Hackathon SGE 2026",
    description: "Desafío de desarrollo de 48 horas para crear soluciones innovadoras en la gestión de eventos corporativos.",
    city: "Lima",
    address: "Oficinas SGE Miraflores",
    start_date: 3.days.from_now,
    end_date: 5.days.from_now,
    price: 0.00,
    currency: "PEN",
    max_capacity: 100,
    status: :published,
    category: Category.find_by(slug: "tecnologia"),
    organizer: admin_user,
    images: ["https://picsum.photos/800/600?random=4"]
  },
  {
    name: "Taller de Pintura Óleo",
    description: "Taller básico e intermedio dictado por renombrados artistas locales. Materiales incluidos.",
    city: "Cusco",
    address: "Galería de Arte Contemporáneo",
    start_date: 5.months.from_now,
    end_date: 5.months.from_now + 3.days,
    price: 150.00,
    currency: "PEN",
    max_capacity: 30,
    status: :draft,
    category: Category.find_by(slug: "arte-y-cultura"),
    organizer: organizer_user,
    images: ["https://picsum.photos/800/600?random=5"]
  }
]

event_data.each do |e_data|
  event = Event.find_or_initialize_by(name: e_data[:name])

  # Asignamos los atributos al evento. Si es un nuevo registro, los establecerá.
  # Si ya existe, los comparará y marcará 'changed?' si hay diferencias.
  event.assign_attributes(
    description: e_data[:description],
    city: e_data[:city],
    address: e_data[:address],
    start_date: e_data[:start_date],
    end_date: e_data[:end_date],
    price: e_data[:price],
    currency: e_data[:currency],
    max_capacity: e_data[:max_capacity],
    status: e_data[:status],
    category: e_data[:category],
    organizer: e_data[:organizer]
  )

  # Solo guardamos si es un nuevo registro o si algún atributo ha cambiado.
  # Esto asegura que los datos del evento estén siempre actualizados si se modifican las semillas,
  # y evita guardar innecesariamente si no hay cambios.
  if event.new_record? || event.changed?
    event.save!
    puts "Evento creado/actualizado: #{event.name}"
  else
    puts "Evento ya existe y está actualizado: #{event.name}"
  end


  # Procesar imágenes para el evento de forma idempotente
  e_data[:images].each_with_index do |img_url, idx|
    # Solo crea la imagen si no existe una con la misma URL para este evento
    unless event.event_images.exists?(image: img_url)
      event.event_images.create!(
        image: img_url,
        display_order: idx
      )
      puts "  - Imagen agregada al evento '#{event.name}': #{img_url}"
    else
      # Opcional: Si la imagen ya existe pero el display_order podría haber cambiado
      # image = event.event_images.find_by(image: img_url)
      # if image && image.display_order != idx
      #   image.update!(display_order: idx)
      #   puts "  - Orden de imagen actualizado para '#{event.name}': #{img_url}"
      # else
      puts "  - Imagen ya existe para el evento '#{event.name}': #{img_url}"
      # end
    end
  end

  # Agregar comentarios si el evento está publicado y aún no tiene los comentarios predefinidos.
  # Para asegurar la idempotencia en comentarios, solo los creamos una vez al crear el evento,
  # y si no existen para ese evento y usuario en particular.
  if event.published?
    users_for_comments = users.sample(3) # Selecciona 3 usuarios aleatorios para comentar
    users_for_comments.each do |user|
      comment_content = "Este evento se ve extremadamente interesante. Definitivamente voy a asistir con mis colegas."
      # Solo crear el comentario si no existe un comentario idéntico del mismo usuario para este evento
      unless event.comments.exists?(user: user, content: comment_content)
        Comment.create!(
          event: event,
          user: user,
          content: comment_content,
          rating: rand(4..5) # Mantiene la aleatoriedad inicial para el rating
        )
        puts "  - Comentario agregado al evento '#{event.name}' por #{user.email}"
      else
        puts "  - Comentario ya existe para el evento '#{event.name}' por #{user.email}"
      end
    end
  end
end

puts "¡Carga de semillas completada exitosamente!"
