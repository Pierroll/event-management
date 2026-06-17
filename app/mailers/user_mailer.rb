# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def confirmation_code(user, code)
    @user = user
    @code = code
    @expiry_minutes = 15

    mail(to: user.email, subject: "Código de verificación — SGE")
  end
end
