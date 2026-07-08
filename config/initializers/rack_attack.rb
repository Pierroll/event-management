class Rack::Attack
  # `Rack::Attack` is configured to use the `Rails.cache` value by default,
  # but you can override that by setting the `Rack::Attack.cache.store` value

  # Throttle all requests by IP (60 requests/minute)
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip # unless req.path.start_with?('/assets')
  end

  # Throttle API requests by API Token (100 requests/minute)
  throttle('api/token', limit: 100, period: 1.minute) do |req|
    if req.path.start_with?('/api/') && req.env['HTTP_AUTHORIZATION']
      # Extract token from Bearer
      req.env['HTTP_AUTHORIZATION'].split(' ').last
    end
  end

  # Rate Limit Response
  self.throttled_responder = lambda do |request|
    [ 429,  # status
      {'Content-Type' => 'application/json'},   # headers
      [{ error: "Rate limit exceeded. Please wait before making more requests." }.to_json] # body
    ]
  end
end
