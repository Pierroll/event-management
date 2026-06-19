# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def new
    build_resource({})
    resource.selected_role = params[:role] if params[:role].present?
    respond_with resource
  end

  def create
    build_resource(sign_up_params)
    resource.save
    yield resource if block_given?
    
    if resource.persisted?
      code = resource.generate_confirmation_code
      begin
        # Enviar correo de manera síncrona para confirmar su correcta salida
        UserMailer.confirmation_code(resource, code).deliver_now
        session[:unconfirmed_email] = resource.email
        redirect_to new_confirmation_path, notice: t("confirmations.sent")
      rescue StandardError => e
        # Loggear el error para diagnóstico en el servidor (ej: Render)
        Rails.logger.error "[SMTP Error] Falló el envío del código de verificación: #{e.class} - #{e.message}"
        
        # Rollback lógico: eliminar el usuario persistido si no podemos enviarle el mail de confirmación
        resource.destroy
        
        # Inyectar error de validación base para el formulario
        resource.errors.add(:base, "No se pudo enviar el correo de verificación. Por favor, verificá tu configuración de correo.")
        
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
end
