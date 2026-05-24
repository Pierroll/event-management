# Semillas para el Sistema de Gestión de Eventos

puts "Cargando roles por defecto..."
roles = %w[admin organizer registered_user].map do |role_name|
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
  Category.find_or_create_by!(slug: cat_data[:slug]) do |c|
    c.name = cat_data[:name]
    c.description = cat_data[:description]
    c.active = true
  end
end

puts "Creando usuarios iniciales..."

# Admin
admin_user = User.find_or_initialize_by(email: "admin@eventos.com")
if admin_user.new_record?
  admin_user.name = "Admin Principal"
  admin_user.password = "admin123"
  admin_user.password_confirmation = "admin123"
  admin_user.active = true
  admin_user.save!
  admin_user.roles << Role.find_by(name: "admin")
  puts "Admin creado (admin@eventos.com / admin123)"
end

# Organizer
organizer_user = User.find_or_initialize_by(email: "organizer@eventos.com")
if organizer_user.new_record?
  organizer_user.name = "Organizador Oficial"
  organizer_user.password = "organizer123"
  organizer_user.password_confirmation = "organizer123"
  organizer_user.active = true
  organizer_user.save!
  organizer_user.roles << Role.find_by(name: "organizer")
  puts "Organizador creado (organizer@eventos.com / organizer123)"
end

# Registered User
registered_user = User.find_or_initialize_by(email: "user@eventos.com")
if registered_user.new_record?
  registered_user.name = "Juan Pérez"
  registered_user.password = "user123"
  registered_user.password_confirmation = "user123"
  registered_user.active = true
  registered_user.save!
  registered_user.roles << Role.find_by(name: "registered_user")
  puts "Usuario común creado (user@eventos.com / user123)"
end

# Extra users for commenting
users = [registered_user]
5.times do |i|
  u = User.find_or_initialize_by(email: "user#{i}@eventos.com")
  if u.new_record?
    u.name = "Usuario Falso #{i}"
    u.password = "password123"
    u.password_confirmation = "password123"
    u.active = true
    u.save!
    u.roles << Role.find_by(name: "registered_user")
    users << u
  end
end

puts "Creando eventos y fotos de prueba..."
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
  if event.new_record?
    event.description = e_data[:description]
    event.city = e_data[:city]
    event.address = e_data[:address]
    event.start_date = e_data[:start_date]
    event.end_date = e_data[:end_date]
    event.price = e_data[:price]
    event.currency = e_data[:currency]
    event.max_capacity = e_data[:max_capacity]
    event.status = e_data[:status]
    event.category = e_data[:category]
    event.organizer = e_data[:organizer]
    event.save!

    e_data[:images].each_with_index do |img_url, idx|
      event.event_images.create!(
        image: img_url,
        display_order: idx
      )
    end
    puts "Evento creado: #{event.name}"

    # Agregar comentarios si el evento está publicado
    if event.published?
      users.sample(3).each do |user|
        Comment.create!(
          event: event,
          user: user,
          content: "Este evento se ve extremadamente interesante. Definitivamente voy a asistir con mis colegas.",
          rating: rand(4..5)
        )
      end
    end
  end
end

puts "¡Carga de semillas completada exitosamente!"
