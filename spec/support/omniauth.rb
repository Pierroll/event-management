# frozen_string_literal: true

OmniAuth.config.test_mode = true

OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
  provider: "google_oauth2",
  uid: "123456789",
  info: {
    email: "google@example.com",
    name: "Google User",
    email_verified: true
  }
)

def mock_google_auth(email:, name:, uid: "987654321", email_verified: true)
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: "google_oauth2",
    uid: uid,
    info: {
      email: email,
      name: name,
      email_verified: email_verified
    }
  )
end
