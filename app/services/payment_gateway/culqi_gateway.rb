# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module PaymentGateway
  # Real payment gateway integration using Culqi API v2
  class CulqiGateway < Base
    def charge(amount_cents:, currency_code: "PEN", description: nil, email: nil, source_id:)
      amount_cents = amount_cents.to_i

      if amount_cents <= 0
        raise ChargeError, "El monto debe ser mayor a 0"
      end

      private_key = ENV["CULQI_PRIVATE_KEY"]
      if private_key.blank?
        raise ChargeError, "La llave privada de Culqi no está configurada (CULQI_PRIVATE_KEY)"
      end

      uri = URI("https://api.culqi.com/v2/charges")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request["Authorization"] = "Bearer #{private_key}"
      request["Content-Type"] = "application/json"

      payload = {
        amount: amount_cents,
        currency_code: currency_code,
        email: email,
        source_id: source_id,
        capture: true
      }
      payload[:description] = description.truncate(80) if description.present?

      request.body = payload.to_json

      begin
        response = http.request(request)
        response_body = JSON.parse(response.body)

        if response.code.to_i == 201
          {
            success: true,
            charge_id: response_body["id"],
            raw_response: response.body
          }
        else
          error_message = response_body["user_message"] || response_body["merchant_message"] || "Error al procesar el pago con Culqi"
          raise ChargeError, error_message
        end
      rescue JSON::ParserError
        raise ChargeError, "Respuesta inválida del servidor de pagos"
      rescue ChargeError => e
        raise e
      rescue StandardError => e
        raise ChargeError, "Error de conexión con la pasarela de pagos: #{e.message}"
      end
    end

    def create_order(amount_cents:, currency_code: "PEN", description:, email:, first_name:, last_name:, phone_number: nil, expires_at:)
      amount_cents = amount_cents.to_i
      private_key = ENV["CULQI_PRIVATE_KEY"]
      if private_key.blank?
        raise ChargeError, "La llave privada de Culqi no está configurada (CULQI_PRIVATE_KEY)"
      end

      uri = URI("https://api.culqi.com/v2/orders")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request["Authorization"] = "Bearer #{private_key}"
      request["Content-Type"] = "application/json"

      payload = {
        amount: amount_cents,
        currency_code: currency_code,
        description: description.to_s.truncate(80),
        order_number: "ord-booking-#{SecureRandom.hex(6)}",
        client_details: {
          first_name: first_name.presence || "Cliente",
          last_name: last_name.presence || "SGE",
          email: email,
          phone_number: phone_number.presence || "+51999999999"
        },
        expiration_date: (Time.current + 24.hours).to_i,
        confirm: false
      }

      request.body = payload.to_json

      begin
        response = http.request(request)
        response_body = JSON.parse(response.body)

        if response.code.to_i == 201
          {
            success: true,
            order_id: response_body["id"],
            raw_response: response.body
          }
        else
          error_message = response_body["user_message"] || response_body["merchant_message"] || "Error al crear la orden en Culqi"
          raise ChargeError, error_message
        end
      rescue JSON::ParserError
        raise ChargeError, "Respuesta inválida del servidor de pagos"
      rescue ChargeError => e
        raise e
      rescue StandardError => e
        raise ChargeError, "Error de conexión al crear orden de pago: #{e.message}"
      end
    end

    def get_order(order_id:)
      private_key = ENV["CULQI_PRIVATE_KEY"]
      if private_key.blank?
        raise ChargeError, "La llave privada de Culqi no está configurada (CULQI_PRIVATE_KEY)"
      end

      uri = URI("https://api.culqi.com/v2/orders/#{order_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.path)
      request["Authorization"] = "Bearer #{private_key}"

      begin
        response = http.request(request)
        response_body = JSON.parse(response.body)

        if response.code.to_i == 200
          {
            success: true,
            state: response_body["state"],
            raw_response: response.body
          }
        else
          error_message = response_body["user_message"] || response_body["merchant_message"] || "Error al consultar la orden"
          raise ChargeError, error_message
        end
      rescue JSON::ParserError
        raise ChargeError, "Respuesta inválida del servidor de pagos"
      rescue ChargeError => e
        raise e
      rescue StandardError => e
        raise ChargeError, "Error de conexión al consultar orden de pago: #{e.message}"
      end
    end
  end
end
