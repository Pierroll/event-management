// Stimulus controllers index
import { application } from "controllers/application"

// Manual registration for controllers needed before lazy loading
import ConfirmController from "controllers/confirm_controller"
application.register("confirm", ConfirmController)

import NavbarController from "controllers/navbar_controller"
application.register("navbar", NavbarController)

import TicketTypesController from "controllers/ticket_types_controller"
application.register("ticket-types", TicketTypesController)

import ShareController from "controllers/share_controller"
application.register("share", ShareController)

import QrModalController from "controllers/qr_modal_controller"
application.register("qr-modal", QrModalController)

// Eager load all other controllers defined in this directory
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
