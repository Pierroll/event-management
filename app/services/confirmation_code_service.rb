# frozen_string_literal: true

# Handles 6-digit confirmation code lifecycle:
# - Generate: creates random 6-digit code, stores SHA256 hash
# - Verify: checks against hash, enforces 3-attempt limit and 15-min expiry
# - Resend: rate-limited to 1 per 60 seconds
class ConfirmationCodeService
  CODE_EXPIRY = 15.minutes
  MAX_ATTEMPTS = 3
  RESEND_COOLDOWN = 60.seconds

  def self.generate(user)
    code = rand(100_000..999_999).to_s
    hashed = Digest::SHA256.hexdigest(code)
    user.update!(
      confirmation_code: hashed,
      confirmation_sent_at: Time.current,
      confirmation_attempts: 0
    )
    code
  end

  def self.verify(user, code)
    return false if user.confirmation_code.blank?
    return false if code_expired?(user)
    return false if attempts_exhausted?(user)

    if user.confirmation_code == Digest::SHA256.hexdigest(code)
      user.update!(confirmed_at: Time.current, confirmation_code: nil, confirmation_attempts: 0)
      true
    else
      user.increment!(:confirmation_attempts)
      false
    end
  end

  def self.invalidate(user)
    user.update!(confirmation_code: nil, confirmation_attempts: 0)
  end

  def self.can_resend?(user)
    return true if user.confirmation_sent_at.nil?

    Time.current - user.confirmation_sent_at >= RESEND_COOLDOWN
  end

  def self.code_expired?(user)
    return true if user.confirmation_sent_at.nil?

    Time.current - user.confirmation_sent_at > CODE_EXPIRY
  end

  def self.attempts_exhausted?(user)
    user.confirmation_attempts >= MAX_ATTEMPTS
  end
end
