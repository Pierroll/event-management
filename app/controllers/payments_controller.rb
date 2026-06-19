# frozen_string_literal: true

class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking

  def new
    @payment = @booking.build_payment
    authorize @payment

    redirect_to booking_path(@booking), alert: "Esta reserva ya expiró." and return if @booking.expired_unpaid?
    redirect_to booking_path(@booking), alert: "Esta reserva ya fue confirmada." and return if @booking.confirmed?
  end

  def create
    @payment = @booking.build_payment
    authorize @payment

    if @booking.expired_unpaid?
      redirect_to booking_path(@booking), alert: "La reserva expiró. Realizá una nueva." and return
    end

    service = Payments::ChargeService.call(@booking, params[:culqi_token_id])

    if service.approved?
      redirect_to booking_path(@booking), notice: "Pago exitoso. Tu reserva está confirmada."
    else
      redirect_to new_booking_payment_path(@booking), alert: "El pago fue rechazado. Intentá de nuevo."
    end
  rescue Payments::ChargeService::ChargeError => e
    redirect_to booking_path(@booking), alert: e.message
  end

  private

  def set_booking
    @booking = current_user.bookings.find(params[:booking_id])
  end
end
