# frozen_string_literal: true

class BookingsController < ApplicationController
  include EventScoping

  before_action :authenticate_user!
  before_action -> { set_event(id_key: :event_id) }, only: [:new, :create]
  before_action :set_ticket_type, only: [:new, :create]

  def index
    # TODO(arquitectura): si el filtrado de bookings crece en
    # complejidad (más de 2-3 condiciones), extraer a
    # Bookings::SearchQuery siguiendo el patrón de Events::SearchQuery
    @bookings = policy_scope(Booking)
                  .includes(event: [:category])
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(10)
  end

  def show
    @booking = Booking.includes(:tickets, event: [:category, :event_images]).find(params[:id])
    authorize @booking
  end

  def new
    @booking = Booking.new
    authorize @booking
    @ticket_types = @event.ticket_types.ordered.on_sale
  end

  def create
    @booking = Booking.new
    authorize @booking

    begin
      @booking = Bookings::CreateService.call(current_user, @ticket_type, quantity: booking_params[:quantity])
      redirect_to @booking, notice: t("bookings.created")
    rescue Bookings::CreateService::CapacityExceededError => e
      redirect_to @event, alert: e.message
    end
  end

  private

  def set_ticket_type
    return unless params[:ticket_type_id].present?

    @ticket_type = @event.ticket_types.find(params[:ticket_type_id])
  end

  def booking_params
    params.require(:booking).permit(:quantity)
  end
end
