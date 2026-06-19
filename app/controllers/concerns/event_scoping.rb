# frozen_string_literal: true

# Encapsulates the three distinct patterns for finding an Event record
# across controllers that work with events.
#
# Usage:
#   set_event                    # params[:id], sin scope (EventsController)
#   set_event(id_key: :event_id) # params[:event_id], sin scope (Bookings, Comments)
#   set_event(scope: :organizer) # params[:id] scoped al organizer (CheckIns)
#
# Nota: la autorización sigue siendo responsabilidad de Pundit en cada acción.
# Este concern solo resuelve el evento y lo deja en @event.
module EventScoping
  extend ActiveSupport::Concern

  private

  def set_event(id_key: :id, scope: :none)
    event_id = params.fetch(id_key)

    @event = if scope == :organizer && !current_user.admin?
               current_user.organized_events.find(event_id)
             else
               Event.find(event_id)
             end
  end
end
