Geocoder.configure(
  # geocoding options
  timeout: 5,                 # geocoding service timeout (secs)
  lookup: :nominatim,         # name of geocoding service (symbol)
  ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  language: :es,              # ISO-639 language code
  
  # HTTP options
  http_headers: { 
    "User-Agent" => "SGE_App_Production (admin@actify.com)" # REQUERIDO POR NOMINATIM EN VPS
  },
  
  # Exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and Timeout::Error
  always_raise: :all,

  # Calculation options
  units: :km,                 # :km for kilometers or :mi for miles
  distances: :linear          # :spherical or :linear
)
