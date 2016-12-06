module SlackHelper
  def self.log(body)
    route = ENV['SLACK_EXCEPTIONS_ROUTE']
    return false if route.blank?
    domain = ENV['DOMAIN']
    return false unless domain == 'api.noncents.co'
    return false unless Rails.env.production?
    notifier = Slack::Notifier.new("https://hooks.slack.com/services/" + route)
    notifier.ping body
    true
  end
end
