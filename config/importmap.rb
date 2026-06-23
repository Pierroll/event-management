# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "controllers/flash_controller", to: "controllers/flash_controller.js"
pin "controllers/confirm_controller", to: "controllers/confirm_controller.js"
pin "controllers/navbar_controller", to: "controllers/navbar_controller.js"
pin "controllers/ticket_types_controller", to: "controllers/ticket_types_controller.js"
pin "controllers/share_controller", to: "controllers/share_controller.js"

# Leaflet for maps
pin "leaflet", to: "https://unpkg.com/leaflet@1.9.4/dist/leaflet-src.js"