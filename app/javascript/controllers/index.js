// Automatically register all Stimulus controllers from this directory
import { application } from "controllers/application"

// Manual registration to avoid MIME type issues with dynamic loading
import FlashController from "controllers/flash_controller"
application.register("flash", FlashController)

import ConfirmController from "controllers/confirm_controller"
application.register("confirm", ConfirmController)

// Eager load all other controllers defined in this directory
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)