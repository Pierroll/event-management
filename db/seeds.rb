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
roles = %w[admin organizer registered_user].map do |role_name|
  Role.find_or_create_by!(name: role_name) do |r|
    r.description = "Rol de #{role_name.humanize}"
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
    address: "Oficinas SGE Miraflores, Av. Larco 890",
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
    address: "Coworking Startups La Molina, Av. Javier Prado 5678",
    start_date: 2.weeks.from_now,
    end_date: 2.weeks.from_now + 8.hours,
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

puts "\n═" * 60
puts "SEMILLAS COMPLETADAS EXITOSAMENTE"
puts "═" * 60
