# frozen_string_literal: true

# ══════════════════════════════════════════════════════════════
# SEMILLAS PARA SGE — Sistema de Gestión de Eventos
# Completamente idempotente: se puede ejecutar N veces
# sin duplicar datos.
# ══════════════════════════════════════════════════════════════

puts "═" * 60
puts "CARGANDO SEMILLAS — SGE"
puts "═" * 60

# ──────────────────────────────────────────────
# 1. ROLES
# ──────────────────────────────────────────────
puts "\n→ Roles..."
roles = ['admin', 'organizer', 'registered_user', 'dev']
roles.each do |role_name|
  Role.find_or_create_by!(name: role_name) do |role|
    role.description = "Role for #{role_name}"
  end
end
puts "  ✓ #{roles.size} roles listos"

# ──────────────────────────────────────────────
# 2. CATEGORÍAS
# ──────────────────────────────────────────────
puts "\n→ Categorías..."
categories_data = [
  { name: "Tecnología",    slug: "tecnologia",      description: "Eventos, hackathons y conferencias de tecnología" },
  { name: "Música",        slug: "musica",           description: "Conciertos, festivales y shows en vivo" },
  { name: "Deportes",      slug: "deportes",         description: "Torneos, partidos y actividades deportivas" },
  { name: "Arte y Cultura", slug: "arte-y-cultura",  description: "Exposiciones, teatro y eventos culturales" },
  { name: "Gastronomía",   slug: "gastronomia",      description: "Ferias de comida, catas de vino y cenas" }
]

categories = categories_data.map do |cat_data|
  Category.find_or_create_by!(slug: cat_data[:slug]) do |c|
    c.name = cat_data[:name]
    c.description = cat_data[:description]
    c.active = true
  end
end
puts "  ✓ #{categories.size} categorías listas"

# ──────────────────────────────────────────────
# 3. USUARIOS
# ──────────────────────────────────────────────
puts "\n→ Usuarios..."

def assign_role_idempotently(user, role_name)
  role = Role.find_by(name: role_name)
  return unless role

  user.roles << role unless user.roles.include?(role)
end

users_data = [
  { email: "admin@eventos.com",  name: "Admin Principal",    password: "admin123",     role: "admin" },
  { email: "admin@admin.com",    name: "Admin Local",        password: "admin123",     role: "admin" },
  { email: "organizer@eventos.com", name: "Organizador Oficial", password: "organizer123", role: "organizer" },
  { email: "user@eventos.com",   name: "Juan Pérez",         password: "user123",      role: "registered_user" }
]

created_users = users_data.map do |data|
  user = User.find_or_initialize_by(email: data[:email])
  if user.new_record?
    user.name = data[:name]
    user.password = data[:password]
    user.password_confirmation = data[:password]
    user.active = true
    user.confirmed_at = Time.current
    user.selected_role = data[:role]
    user.save!
    puts "  + Creado: #{data[:email]} (#{data[:role]})"
  else
    puts "  ✓ Ya existe: #{data[:email]}"
  end
  assign_role_idempotently(user, data[:role])
  user
end

# Usuarios extra para comentarios
extra_users = []
5.times do |i|
  user = User.find_or_initialize_by(email: "user#{i}@eventos.com")
  if user.new_record?
    user.name = "Usuario Falso #{i}"
    user.password = "password123"
    user.password_confirmation = "password123"
    user.active = true
    user.confirmed_at = Time.current
    user.selected_role = "registered_user"
    user.save!
    puts "  + Creado extra: #{user.email}"
  end
  assign_role_idempotently(user, "registered_user")
  extra_users << user
end

all_users = created_users + extra_users
puts "  ✓ #{all_users.size} usuarios en total"

# ──────────────────────────────────────────────
# 4. EVENTOS + TICKET TYPES + IMÁGENES
# ──────────────────────────────────────────────
puts "\n→ Eventos, TicketTypes e imágenes..."

# Imágenes reales de Unsplash (eventos reales, licencia gratuita)
IMAGES = {
  conference: %w[
    https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1511578314322-379afb476865?w=800&h=600&fit=crop
  ],
  coding: %w[
    https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&h=600&fit=crop
  ],
  concert: %w[
    https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop
  ],
  festival: %w[
    https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=800&h=600&fit=crop
  ],
  sports: %w[
    https://images.unsplash.com/photo-1461896836934-bd45ba8fcf0b?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1574629810360-8efceed2c6c4?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800&h=600&fit=crop
  ],
  art: %w[
    https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1531913764164-f85c3e01a288?w=800&h=600&fit=crop
  ],
  food: %w[
    https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop
  ],
  workshop: %w[
    https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=800&h=600&fit=crop
    https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&h=600&fit=crop
  ]
}.freeze

events_data = [
  {
    name: "Rails World 2026",
    description: "La conferencia mundial más grande de Ruby on Rails, reuniendo a creadores y profesionales de todo el mundo. Charlas técnicas, workshops y networking con los líderes de la comunidad Rails.",
    city: "Lima",
    address: "Centro de Convenciones de Lima, Av. La Marina 1234",
    latitude: -12.078,
    longitude: -77.086,
    start_date: 2.months.from_now,
    end_date: 2.months.from_now + 2.days,
    currency: "USD",
    max_capacity: 500,
    status: :published,
    category_slug: "tecnologia",
    organizer_email: "organizer@eventos.com",
    image_set: :conference,
    ticket_types: [
      { name: "Entrada General",   price: 150.00, quantity_total: 300, max_per_order: 5,  position: 0 },
      { name: "VIP",               price: 350.00, quantity_total: 100, max_per_order: 2,  position: 1 },
      { name: "Early Bird",        price: 99.00,  quantity_total: 100, max_per_order: 2,  position: 2,
        sales_end_at: 1.month.from_now }
    ]
  },
  {
    name: "Festival de Rock Latino",
    description: "Los mejores exponentes del rock en español en un solo escenario durante 12 horas seguidas. Bandas de toda Latinoamérica, food trucks y zona de camping habilitada.",
    city: "Arequipa",
    address: "Jardín de la Cerveza, Av. Ejército 567",
    latitude: -16.409,
    longitude: -71.537,
    start_date: 1.month.from_now,
    end_date: 1.month.from_now + 12.hours,
    currency: "PEN",
    max_capacity: 10_000,
    status: :published,
    category_slug: "musica",
    organizer_email: "organizer@eventos.com",
    image_set: :concert,
    ticket_types: [
      { name: "Entrada General",   price: 80.00,  quantity_total: 7_000, max_per_order: 10, position: 0 },
      { name: "VIP + Backstage",   price: 250.00, quantity_total: 1_000, max_per_order: 4,  position: 1 },
      { name: "Camping Pass",      price: 120.00, quantity_total: 2_000, max_per_order: 2,  position: 2 }
    ]
  },
  {
    name: "Hackathon SGE 2026",
    description: "Desafío de desarrollo de 48 horas para crear soluciones innovadoras en la gestión de eventos corporativos. Equipos de hasta 4 personas. Premios para los 3 primeros lugares.",
    city: "Lima",
    address: "Avenida Larco 890, Miraflores, Lima, Perú",
    latitude: -12.122,
    longitude: -77.031,
    start_date: 3.days.from_now,
    end_date: 5.days.from_now,
    currency: "PEN",
    max_capacity: 100,
    status: :published,
    category_slug: "tecnologia",
    organizer_email: "admin@eventos.com",
    image_set: :coding,
    ticket_types: [
      { name: "Participante",  price: 0,     quantity_total: 80,  max_per_order: 4, position: 0 },
      { name: "Esponsor",      price: 500.00, quantity_total: 20,  max_per_order: 1, position: 1 }
    ]
  },
  {
    name: "Taller de Pintura al Óleo",
    description: "Taller básico e intermedio dictado por renombrados artistas locales. Materiales incluidos. Ideal para principiantes y nivel intermedio. Cupos limitados.",
    city: "Cusco",
    address: "Galería de Arte Contemporáneo, Calle San Agustín 234",
    latitude: -13.516,
    longitude: -71.977,
    start_date: 5.months.from_now,
    end_date: 5.months.from_now + 3.days,
    currency: "PEN",
    max_capacity: 30,
    status: :draft,
    category_slug: "arte-y-cultura",
    organizer_email: "organizer@eventos.com",
    image_set: :art,
    ticket_types: [
      { name: "Taller Completo", price: 150.00, quantity_total: 30, max_per_order: 2, position: 0 }
    ]
  },
  {
    name: "Maratón Internacional de Lima",
    description: "42K, 21K y 10K por las calles más emblemáticas de Lima. Recorrido certificado internacionalmente. Hidratación, medallas y poleras para todos los participantes.",
    city: "Lima",
    address: "Parque Kennedy, Miraflores",
    latitude: -12.121,
    longitude: -77.029,
    start_date: 3.months.from_now,
    end_date: 3.months.from_now + 6.hours,
    currency: "PEN",
    max_capacity: 5_000,
    status: :published,
    category_slug: "deportes",
    organizer_email: "organizer@eventos.com",
    image_set: :sports,
    ticket_types: [
      { name: "10K",           price: 30.00,  quantity_total: 2_000, max_per_order: 3, position: 0 },
      { name: "21K Media",     price: 50.00,  quantity_total: 1_500, max_per_order: 3, position: 1 },
      { name: "42K Completa",  price: 80.00,  quantity_total: 1_000, max_per_order: 2, position: 2 },
      { name: "VIP (Kit Premium)", price: 150.00, quantity_total: 500, max_per_order: 2, position: 3 }
    ]
  },
  {
    name: "Feria Gastronómica Sabores del Perú",
    description: "Lo mejor de la cocina peruana en un solo lugar. Ceviches, anticuchos, lomo saltado y postres tradicionales. Shows de cocina en vivo con chefs premiados.",
    city: "Cusco",
    address: "Plaza de Armas de Cusco",
    latitude: -13.516,
    longitude: -71.978,
    start_date: 6.weeks.from_now,
    end_date: 6.weeks.from_now + 3.days,
    currency: "PEN",
    max_capacity: 3_000,
    status: :published,
    category_slug: "gastronomia",
    organizer_email: "organizer@eventos.com",
    image_set: :food,
    ticket_types: [
      { name: "Entrada General",  price: 20.00,  quantity_total: 2_000, max_per_order: 10, position: 0 },
      { name: "VIP + Degustación", price: 80.00, quantity_total: 700,  max_per_order: 4,  position: 1 },
      { name: "Taller de Cocina",  price: 120.00, quantity_total: 300,  max_per_order: 2,  position: 2 }
    ]
  },
  {
    name: "Electronic Music Fest",
    description: "El festival de música electrónica más grande del sur del Perú. DJs internacionales, shows de luces, láser y pirotecnia. 3 escenarios simultáneos.",
    city: "Arequipa",
    address: "Campiña de Yanahuara",
    latitude: -16.393,
    longitude: -71.542,
    start_date: 45.days.from_now,
    end_date: 45.days.from_now + 2.days,
    currency: "PEN",
    max_capacity: 8_000,
    status: :published,
    category_slug: "musica",
    organizer_email: "organizer@eventos.com",
    image_set: :festival,
    ticket_types: [
      { name: "General 1 Día",      price: 60.00,  quantity_total: 4_000, max_per_order: 6, position: 0 },
      { name: "Pase 2 Días",        price: 100.00, quantity_total: 2_500, max_per_order: 4, position: 1 },
      { name: "VIP 2 Días",         price: 200.00, quantity_total: 1_000, max_per_order: 2, position: 2 },
      { name: "Cabina VIP + Bar",   price: 400.00, quantity_total: 500,   max_per_order: 1, position: 3 }
    ]
  },
  {
    name: "Workshop de Innovación Ágil",
    description: "Taller intensivo de metodologías ágiles para equipos de tecnología. Scrum, Kanban, OKRs y Lean Startup. Certificación incluida al completar el taller.",
    city: "Lima",
    address: "La Molina, Lima, Perú",
    latitude: -12.076,
    longitude: -76.938,
    start_date: 14.days.from_now,
    end_date: 14.days.from_now + 8.hours,
    currency: "PEN",
    max_capacity: 40,
    status: :published,
    category_slug: "tecnologia",
    organizer_email: "organizer@eventos.com",
    image_set: :workshop,
    ticket_types: [
      { name: "Entrada General",  price: 45.00,  quantity_total: 25, max_per_order: 2, position: 0 },
      { name: "Entrada + Material", price: 65.00, quantity_total: 15, max_per_order: 1, position: 1 }
    ]
  }
]

organizer_cache = {}
events_data.each do |e_data|
  event = Event.find_or_initialize_by(name: e_data[:name])
  organizer = organizer_cache[e_data[:organizer_email]] ||= User.find_by(email: e_data[:organizer_email])

  event.assign_attributes(
    description: e_data[:description],
    city: e_data[:city],
    address: e_data[:address],
    start_date: e_data[:start_date],
    end_date: e_data[:end_date],
    currency: e_data[:currency],
    max_capacity: e_data[:max_capacity],
    status: e_data[:status],
    category: Category.find_by(slug: e_data[:category_slug]),
    organizer: organizer
  )

  # ── Imágenes (build ANTES de save para pasar validación) ──
  images = IMAGES[e_data[:image_set]]
  if event.new_record?
    # Evento nuevo: build (no necesita id)
    images.each_with_index do |img_url, idx|
      event.event_images.build(image: img_url, display_order: idx)
    end
    event.save!
    puts "  + Evento: #{event.name}"
  else
    # Evento existente: idempotente
    event.save! if event.changed?
    images.each_with_index do |img_url, idx|
      unless event.event_images.exists?(image: img_url)
        event.event_images.create!(image: img_url, display_order: idx)
      end
    end
    puts "  ~ Evento actualizado: #{event.name}" if event.saved_changes?
  end

  # ── TicketTypes ── (idempotente: por nombre dentro del evento)
  e_data[:ticket_types].each_with_index do |tt_data, idx|
    tt = event.ticket_types.find_or_initialize_by(name: tt_data[:name])
    tt.assign_attributes(
      price: tt_data[:price],
      quantity_total: tt_data[:quantity_total],
      max_per_order: tt_data[:max_per_order],
      position: tt_data[:position] || idx,
      sales_start_at: tt_data[:sales_start_at],
      sales_end_at: tt_data[:sales_end_at]
    )
    if tt.new_record? || tt.changed?
      tt.save!
      puts "    #{tt.new_record? ? '+' : '~'} TicketType: #{tt.name} (#{tt_data[:price]} #{e_data[:currency]})"
    end
  end

  # ── Comentarios (solo para publicados, una vez) ──
  next unless event.published?

  commenters = all_users.sample(3)
  commenters.each do |user|
    content = case e_data[:category_slug]
              when "tecnologia" then "Excelente evento tecnológico, muy bien organizado. Los speakers de primer nivel."
              when "musica"     then "Increíble experiencia musical. El sonido y la producción de primer nivel."
              when "deportes"   then "Muy bien organizado, la ruta espectacular. Definitivamente repetiré."
              when "arte-y-cultura" then "Una experiencia cultural maravillosa. Altamente recomendado."
              when "gastronomia"    then "La mejor comida peruana en un solo lugar. Los chefs una locura."
              else "Este evento se ve extremadamente interesante. Definitivamente voy a asistir."
              end
    unless event.comments.exists?(user: user)
      Comment.create!(event: event, user: user, content: content, rating: rand(4..5))
    end
  end
end

# ──────────────────────────────────────────────
# 5. GENERADOR DINÁMICO DE TINGO MARÍA (24 Eventos)
# ──────────────────────────────────────────────
puts "\n→ Generando 24 eventos de Tingo María..."
tingo_titles = [
  "Fiesta de San Juan Tingo María", "Expo Cacao Tingalés", "Maratón Bella Durmiente", 
  "Festival del Tacacho", "Trekking Cueva de las Lechuzas", "Cata de Café Especial", 
  "Concierto de Cumbia Amazónica", "Feria Gastronómica de la Selva", "Ruta de las Cascadas", 
  "Aniversario de Tingo María", "Carnavales Tingaleses", "Feria de Emprendedores Agrícolas",
  "Fiesta de la Cerveza Artesanal", "Canotaje en el Río Huallaga", "Congreso de Turismo Sostenible",
  "Taller de Fotografía de la Naturaleza", "Exposición de Arte Amazónico", "Festival de la Orquídea",
  "Concurso de Danzas Típicas", "Simposio de Agricultura Ecológica", "Competencia de Motocross",
  "Noche de Mitos y Leyendas", "Feria de Artesanía Local", "Retiro de Yoga en la Selva"
]

category_map = {
  "Fiesta de San Juan Tingo María" => { slug: "arte-y-cultura", img: :festival },
  "Expo Cacao Tingalés" => { slug: "gastronomia", img: :food },
  "Maratón Bella Durmiente" => { slug: "deportes", img: :sports },
  "Festival del Tacacho" => { slug: "gastronomia", img: :food },
  "Trekking Cueva de las Lechuzas" => { slug: "deportes", img: :sports },
  "Cata de Café Especial" => { slug: "gastronomia", img: :food },
  "Concierto de Cumbia Amazónica" => { slug: "musica", img: :concert },
  "Feria Gastronómica de la Selva" => { slug: "gastronomia", img: :food },
  "Ruta de las Cascadas" => { slug: "deportes", img: :sports },
  "Aniversario de Tingo María" => { slug: "arte-y-cultura", img: :festival },
  "Carnavales Tingaleses" => { slug: "arte-y-cultura", img: :festival },
  "Feria de Emprendedores Agrícolas" => { slug: "tecnologia", img: :workshop },
  "Fiesta de la Cerveza Artesanal" => { slug: "gastronomia", img: :food },
  "Canotaje en el Río Huallaga" => { slug: "deportes", img: :sports },
  "Congreso de Turismo Sostenible" => { slug: "tecnologia", img: :conference },
  "Taller de Fotografía de la Naturaleza" => { slug: "arte-y-cultura", img: :art },
  "Exposición de Arte Amazónico" => { slug: "arte-y-cultura", img: :art },
  "Festival de la Orquídea" => { slug: "arte-y-cultura", img: :festival },
  "Concurso de Danzas Típicas" => { slug: "arte-y-cultura", img: :festival },
  "Simposio de Agricultura Ecológica" => { slug: "tecnologia", img: :conference },
  "Competencia de Motocross" => { slug: "deportes", img: :sports },
  "Noche de Mitos y Leyendas" => { slug: "arte-y-cultura", img: :art },
  "Feria de Artesanía Local" => { slug: "arte-y-cultura", img: :art },
  "Retiro de Yoga en la Selva" => { slug: "deportes", img: :workshop }
}

tingo_organizer = User.find_by(email: "organizer@eventos.com")

tingo_titles.each_with_index do |title, index|
  event = Event.find_or_initialize_by(name: title)
  
  cat_info = category_map[title] || { slug: "arte-y-cultura", img: :festival }
  days_offset = (index + 1) * 3 # Desde 3 hasta 72 días en el futuro
  
  # Distribución aleatoria para que se vean dispersos en Tingo María
  lat_offset = rand(-0.0150..0.0150)
  lng_offset = rand(-0.0150..0.0150)
  
  event.assign_attributes(
    description: "Únete a nosotros en Tingo María para '#{title}'. Una experiencia inolvidable en la Puerta de la Amazonía Peruana. ¡Descubre la magia de la selva con nosotros!",
    city: "Tingo María",
    address: "Tingo María, Huánuco, Perú",
    latitude: -9.297 + lat_offset,
    longitude: -76.000 + lng_offset,
    start_date: days_offset.days.from_now,
    end_date: days_offset.days.from_now + 1.day,
    currency: "PEN",
    max_capacity: 500,
    status: :published,
    category: Category.find_by(slug: cat_info[:slug]),
    organizer: tingo_organizer
  )
  
  images = IMAGES[cat_info[:img]]
  if event.new_record?
    images.each_with_index do |img_url, idx|
      event.event_images.build(image: img_url, display_order: idx)
    end
    event.save!
    puts "  + Creado TM: #{event.name}"
  else
    event.save! if event.changed?
    images.each_with_index do |img_url, idx|
      unless event.event_images.exists?(image: img_url)
        event.event_images.create!(image: img_url, display_order: idx)
      end
    end
  end

  # Ticket Types idempotentes
  tt = event.ticket_types.find_or_initialize_by(name: "Entrada General")
  tt.assign_attributes(price: 20.00, quantity_total: 400, max_per_order: 5, position: 0)
  tt.save! if tt.new_record? || tt.changed?
  
  tt2 = event.ticket_types.find_or_initialize_by(name: "Pase VIP")
  tt2.assign_attributes(price: 80.00, quantity_total: 100, max_per_order: 2, position: 1)
  tt2.save! if tt2.new_record? || tt2.changed?
end

# ──────────────────────────────────────────────
# 6. EVENTOS CERCA DE LA ALAMEDA PERU (GEOLOCALIZADOS)
# ──────────────────────────────────────────────
puts "\n→ Generando eventos cerca de Alameda Peru, Tingo María..."

alameda_lat = -9.297
alameda_lng = -76.000

alameda_events = [
  { name: "Feria de Emprendimiento Alameda", slug: "tecnologia", img: :workshop },
  { name: "Tarde Cultural Tingalesa", slug: "arte-y-cultura", img: :art },
  { name: "Concierto Acústico al Aire Libre", slug: "musica", img: :concert },
  { name: "Exposición de Fotografía Local", slug: "arte-y-cultura", img: :art },
  { name: "Festival de la Hoja de Coca", slug: "gastronomia", img: :food },
  { name: "Carrera 5K Alameda", slug: "deportes", img: :sports }
]

alameda_events.each_with_index do |ev_data, index|
  event = Event.find_or_initialize_by(name: ev_data[:name])
  
  # Distribución aleatoria en un radio de ~0.05km a 0.5km (offset de hasta 0.004 grados)
  lat_offset = rand(-0.0040..0.0040)
  lng_offset = rand(-0.0040..0.0040)
  
  event.assign_attributes(
    description: "Evento especial en las cercanías de la Alameda Perú. ¡No te lo pierdas!",
    city: "Tingo María",
    address: "Alameda Perú, Tingo María, Huánuco",
    latitude: alameda_lat + lat_offset,
    longitude: alameda_lng + lng_offset,
    start_date: (index + 2).days.from_now,
    end_date: (index + 2).days.from_now + 4.hours,
    currency: "PEN",
    max_capacity: 300,
    status: :published,
    category: Category.find_by(slug: ev_data[:slug]),
    organizer: tingo_organizer
  )
  
  images = IMAGES[ev_data[:img]]
  if event.new_record?
    images.each_with_index { |img, idx| event.event_images.build(image: img, display_order: idx) }
    event.save!
    puts "  + Creado Evento Alameda: #{event.name}"
  else
    event.save! if event.changed?
    images.each_with_index do |img, idx|
      event.event_images.create!(image: img, display_order: idx) unless event.event_images.exists?(image: img)
    end
  end

  tt = event.ticket_types.find_or_initialize_by(name: "Ingreso General")
  tt.assign_attributes(price: 15.00, quantity_total: 300, max_per_order: 4, position: 0)
  tt.save! if tt.new_record? || tt.changed?
end

puts "\n═" * 60
puts "SEMILLAS COMPLETADAS EXITOSAMENTE"
puts "═" * 60
