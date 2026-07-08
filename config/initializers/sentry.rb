Sentry.init do |config|
  config.dsn = 'https://1f0f8c0da5351d997ab51420938a0334@o4511699540377600.ingest.us.sentry.io/4511699545686016'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Add data like request headers and IP for users
  config.send_default_pii = true
end
