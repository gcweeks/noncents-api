module NotificationHelper
  require 'net/http'
  require 'uri'

  def init_notification_vars
    @NONCENTS_FIREBASE_KEY = ENV['NONCENTS_FIREBASE_KEY']
  end

  def test_notification(user)
    return false unless user

    # Populate Topic
    topic = 'user_' + user.id.to_s

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

  def send_notification(topic, data)
    return nil if Rails.env.test?
    init_notification_vars
    url = URI.parse('https://fcm.googleapis.com/fcm/send')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(url.to_s)
    req['Authorization'] = 'key=' + @FIREBASE_KEY
    req['Content-Type'] = 'application/json'
    req.body = {
      'to' => '/topics/' + topic,
      'data' => data
    }.to_json
    res = http.request(req)
    res.body
  end

  def process_response(_res)
    # TODO: Process response
  end
end
