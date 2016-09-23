module SlackHelper
  def self.log(body)
    route = ENV['SLACK_EXCEPTIONS_ROUTE']
    return false if route.blank?
    notifier = Slack::Notifier.new("https://hooks.slack.com/services/" + route)
    notifier.ping body
    true
  end
end
