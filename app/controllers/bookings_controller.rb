# frozen_string_literal: true

class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: [:new, :create]

  def index
    @bookings = policy_scope(Booking)
                  .includes(event: [:category])
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(10)
  end

  def show
    @booking = Booking.includes(event: [:category, :event_images]).find(params[:id])
    authorize @booking
  end

  def new
    @booking = Booking.new
    authorize @booking
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.user = current_user
    @booking.event = @event
    @booking.booked_at = Time.current
    authorize @booking

    begin
      @booking = BookingService.create(current_user, @event, quantity: booking_params[:quantity])
      redirect_to @booking, notice: t("bookings.created")
    rescue BookingService::CapacityExceededError => e
      redirect_to @event, alert: e.message
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def booking_params
    params.require(:booking).permit(:quantity)
  end
end
