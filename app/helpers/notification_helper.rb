module NotificationHelper
  require 'net/http'
  require 'uri'

  def init_notification_vars
    @FIREBASE_KEY = ENV['NONCENTS_FIREBASE_KEY']
  end

  def register_token_fcm(user, token)
    return true if Rails.env.test?
    return false unless token
    init_notification_vars
    url = URI.parse('https://fcm.googleapis.com/fcm/send')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(url.to_s)
    req['Authorization'] = 'key=' + @FIREBASE_KEY
    req['Content-Type'] = 'application/json'
    if user.fcm_key
      req.body = {
        'operation' => 'add',
        'notification_key_name' => 'user_' + user.id.to_s,
        'notification_key' => user.fcm_key,
        'registration_ids' => [token]
      }.to_json
      ret = http.request(req)
      # TODO check response
    else
      req.body = {
        'operation' => 'create',
        'notification_key_name' => 'user_' + user.id.to_s,
        'registration_ids' => [token]
      }.to_json
      ret = http.request(req)
      fcm_key = ret.body['notification_key']
      return false unless fcm_key
      user.fcm_key = fcm_key
      user.save!
    end
    true
  end

  def test_notification(user)
    return false unless user

    # Populate Group
    group = 'user_' + user.id.to_s

    # Populate Data
    data = {
      'hello' => 'world',
      'fname' => user.fname,
      'lname' => user.lname
    }

    # Send Notification
    res = send_notification(topic, data)
    process_response(res)
    true
  end

  private

  def send_notification(group, data)
    return nil if Rails.env.test?
    init_notification_vars
    url = URI.parse('https://fcm.googleapis.com/fcm/send')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(url.to_s)
    req['Authorization'] = 'key=' + @FIREBASE_KEY
    req['Content-Type'] = 'application/json'
    req.body = {
      'to' => group,
      'data' => data
    }.to_json
    res = http.request(req)
    res.body
  end

  def process_response(res)
    # TODO: Process response
    logger.info res
  end
end
