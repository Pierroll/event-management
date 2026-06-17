# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConfirmationCodeService do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@confirmation.com",
      password: "password123",
      confirmed_at: nil,
      confirmation_code: nil,
      confirmation_sent_at: nil,
      confirmation_attempts: 0
    )
  end

  describe ".generate" do
    it "returns a 6-digit string code" do
      code = described_class.generate(user)
      expect(code).to match(/\A\d{6}\z/)
    end

    it "stores SHA256 hash in confirmation_code" do
      code = described_class.generate(user)
      expect(user.reload.confirmation_code).to eq(Digest::SHA256.hexdigest(code))
    end

    it "sets confirmation_sent_at" do
      described_class.generate(user)
      expect(user.reload.confirmation_sent_at).to be_present
    end

    it "resets confirmation_attempts to 0" do
      user.update!(confirmation_attempts: 3)
      described_class.generate(user)
      expect(user.reload.confirmation_attempts).to eq(0)
    end
  end

  describe ".verify" do
    before do
      described_class.generate(user)
    end

    it "returns true and sets confirmed_at for correct code" do
      code = described_class.generate(user)
      result = described_class.verify(user, code)
      expect(result).to be true
      expect(user.reload.confirmed_at).to be_present
    end

    it "returns false for wrong code" do
      result = described_class.verify(user, "000000")
      expect(result).to be false
    end

    it "increments confirmation_attempts on wrong code" do
      expect { described_class.verify(user, "000000") }
        .to change { user.reload.confirmation_attempts }.by(1)
    end

    it "tracks attempts and allows external invalidation after 3 failures" do
      described_class.verify(user, "111111")
      described_class.verify(user, "222222")
      expect { described_class.verify(user, "333333") }
        .to change { user.reload.confirmation_attempts }.to(3)
    end

    it "returns false for expired code" do
      user.update!(confirmation_sent_at: 16.minutes.ago)
      result = described_class.verify(user, "000000")
      expect(result).to be false
    end

    it "returns false when no code exists" do
      user.update!(confirmation_code: nil)
      expect(described_class.verify(user, "000000")).to be false
    end
  end

  describe ".can_resend?" do
    it "returns true if no code was sent before" do
      expect(described_class.can_resend?(user)).to be true
    end

    it "returns false if sent less than 60 seconds ago" do
      described_class.generate(user)
      expect(described_class.can_resend?(user)).to be false
    end

    it "returns true if sent more than 60 seconds ago" do
      user.update!(confirmation_sent_at: 61.seconds.ago)
      expect(described_class.can_resend?(user)).to be true
    end
  end

  describe ".code_expired?" do
    it "returns true if confirmation_sent_at is nil" do
      expect(described_class.code_expired?(user)).to be true
    end

    it "returns true if sent more than 15 minutes ago" do
      user.update!(confirmation_sent_at: 16.minutes.ago)
      expect(described_class.code_expired?(user)).to be true
    end

    it "returns false if sent less than 15 minutes ago" do
      user.update!(confirmation_sent_at: 10.minutes.ago)
      expect(described_class.code_expired?(user)).to be false
    end
  end

  describe ".invalidate" do
    it "clears confirmation_code and resets attempts" do
      described_class.generate(user)
      described_class.invalidate(user)
      expect(user.reload.confirmation_code).to be_nil
      expect(user.confirmation_attempts).to eq(0)
    end
  end
end
