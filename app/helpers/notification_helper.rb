module NotificationHelper
  require 'net/http'
  require 'uri'

  def init_notification_vars
    @FIREBASE_KEY = ENV['NONCENTS_FIREBASE_KEY']
  end

  def register_token_fcm(user, token)
    return false unless user && token

    # The FcmToken model acts as a lookup table to see if a different User has
    # previously registered the same device token before. This can happen if a
    # client logs into another account on the same device.

    # Find FcmToken or create one if it doesn't exist
    fcm_token = FcmToken.find_by(token: token)
    unless fcm_token
      fcm_token = FcmToken.new(token: token)
      fcm_token.user = user
      fcm_token.save!
      return true
    end

    # If User ID doesn't match, update it
    if fcm_token.user.id != user.id
      fcm_token.user = user
      fcm_token.save!
    end

    true
  end

  def test_notification(user, title, body)
    return false unless user

    # Populate Notification
    notification = {
      'title' => title,
      'body' => body
    }

    # Send Notification
    res = send_notification(user, notification, nil)
    process_response(res)
    true
  end

  private

  def send_notification(user, notification, body)
    return true if Rails.env.test?
    return false unless user
    init_notification_vars
    url = URI.parse('https://fcm.googleapis.com/fcm/send')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(url.to_s)
    req['Authorization'] = 'key=' + @FIREBASE_KEY
    req['Content-Type'] = 'application/json'

    # Send notification to each of the User's registered devices
    ret = true
    req.body = {
      'priority' => 'high'
    }
    req.body['notification'] = notification if notification
    req.body['body'] = body if body
    for token in user.fcm_tokens
      req.body['to'] = token
      res = http.request(req.to_json)
      ret &&= process_response(res)
    end
    ret
  end

  def process_response(res)
    logger.info "FCM Response: " + res.body
    # TODO: Process response
    true
  end
end
