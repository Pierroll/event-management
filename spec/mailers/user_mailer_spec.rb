# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#confirmation_code" do
    let(:user) do
      User.create!(
        name: "Mailer User",
        email: "mailer@test.com",
        password: "password123"
      )
    end
    let(:code) { "483921" }
    let(:mail) { described_class.confirmation_code(user, code) }

    it "renders the headers" do
      expect(mail.subject).to eq("Código de verificación — SGE")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["kodexworks@gmail.com"])
    end

    it "renders the code in the body" do
      expect(mail.body.encoded).to include(code)
    end

    it "renders the expiration notice" do
      expect(mail.body.encoded).to include("15 minutos")
    end

  end
end
