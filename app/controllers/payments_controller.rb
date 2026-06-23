# frozen_string_literal: true

class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking

  def new
    @payment = @booking.build_payment
    authorize @payment

    redirect_to booking_path(@booking), alert: "Esta reserva ya expiró." and return if @booking.expired_unpaid?
    redirect_to booking_path(@booking), alert: "Esta reserva ya fue confirmada." and return if @booking.confirmed?

    # Create order in Culqi to enable alternative payment methods (Yape/Plin)
    begin
      gateway = PaymentGateway.instance
      name_parts = current_user.name.to_s.split(" ")
      first_name = name_parts.first || "Cliente"
      last_name = name_parts[1..].join(" ")
      last_name = "SGE" if last_name.blank?

      amount_cents = (@booking.total_price * 100).to_i

      order_result = gateway.create_order(
        amount_cents: amount_cents,
        currency_code: "PEN",
        description: "Reserva ##{@booking.id} - #{@booking.event.name}",
        email: current_user.email,
        first_name: first_name,
        last_name: last_name,
        expires_at: @booking.expires_at
      )

      @order_id = order_result[:order_id]
    rescue => e
      Rails.logger.error "[Culqi Orders] Error creating order: #{e.message}"
      @order_id = nil
    end
  end

  def create
    @payment = @booking.build_payment
    authorize @payment

    if @booking.expired_unpaid?
      redirect_to booking_path(@booking), alert: "La reserva expiró. Realizá una nueva." and return
    end

    if params[:culqi_order_id].present?
      # Verify order payment (Yape/Plin)
      service = Payments::VerifyOrderService.call(@booking, params[:culqi_order_id])
      approved = service.present?
    elsif params[:culqi_token_id].present?
      # Process card payment
      service = Payments::ChargeService.call(@booking, params[:culqi_token_id])
      approved = service.approved?
    else
      approved = false
    end

    if approved
      redirect_to booking_path(@booking), notice: "Pago exitoso. Tu reserva está confirmada."
    else
      redirect_to new_booking_payment_path(@booking), alert: "El pago fue rechazado. Intentá de nuevo."
    end
  rescue Payments::ChargeService::ChargeError => e
    redirect_to booking_path(@booking), alert: e.message
  rescue Payments::VerifyOrderService::OrderError => e
    redirect_to booking_path(@booking), alert: e.message
  end

  private

  def set_booking
    @booking = current_user.bookings.find(params[:booking_id])
  end
end
