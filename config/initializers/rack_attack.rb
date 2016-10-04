class Rack::Attack
  if ENV['REDIS_HOST'].present?
    $redis = Redis.new(host: ENV['REDIS_HOST'], port: 6379)
  elsif ENV['DOMAIN'] == 'api.noncents.co'
    SlackHelper.log('Production launced without Redis')
  elsif !Rails.env.production?
    $redis = Redis.new(host: 'localhost', port: 6379)
  end

  # Comment to enable rate limiting in other environments:
  if $redis && !Rails.env.test? && !Rails.env.development?
    ### Configure Cache ###

    Rack::Attack.cache.store = Rack::Attack::StoreProxy::RedisStoreProxy.new($redis)

    ### Throttle Spammy Clients ###

    # If any single client IP is making tons of requests, then they're
    # probably malicious or a poorly-configured scraper. Either way, they
    # don't deserve to hog all of the app server's CPU. Cut them off!

    # Throttle all requests by IP (60 req/min)
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
    throttle('req/ip', :limit => 300, :period => 5.minutes) do |req|
      req.ip
    end

    ### Prevent Brute-Force Login Attacks ###

    # The most common brute-force login attack is a brute-force password
    # attack where an attacker simply tries a large number of emails and
    # passwords to see if any credentials match.
    #
    # Another common method of attack is to use a swarm of computers with
    # different IPs to try brute-forcing a password for a specific account.

    # Throttle POST requests to /login by IP address
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
    throttle('logins/ip', :limit => 5, :period => 20.seconds) do |req|
      if req.path == '/v1/auth'
        req.ip
      end
    end

    # Throttle POST requests to /login by email param
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{req.email}"
    #
    # Note: This creates a problem where a malicious user could intentionally
    # throttle logins for another user and force their login requests to be
    # denied, but that's not very common and shouldn't happen (Knock on wood!)
    throttle("logins/email", :limit => 5, :period => 20.seconds) do |req|
      if req.path == '/v1/auth'
        user = req.params['user'].presence
        # return the email if present, nil otherwise
        user['email'].presence if user
      end
    end

    ### Custom Throttle Response ###

    # By default, Rack::Attack returns an HTTP 429 for throttled responses.
    #
    # Return 503 so that the attacker might be fooled into believing that they've
    # successfully broken the app.
    # self.throttled_response = lambda do |env|
    #  [ 503,  # status
    #    {},   # headers
    #    ['']] # body
    # end

    ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
      # "Throttled `/v1/auth` for IP `127.0.0.1` with email `cashmoney@gmail.com`"
      error = 'Throttled `' + req.path + '` for IP `' + req.ip + '`'
      # Log email if being throttled for email reasons
      if req.path == '/v1/auth'
        user = req.params['user'].presence
        if user && user['email'].present?
          error = error + ' with email `' + user['email'] + '`'
        end
      end
      SlackHelper.log(error)
    end
  end
end
