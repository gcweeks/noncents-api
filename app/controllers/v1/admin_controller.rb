class V1::AdminController < ApplicationController
  before_action :init
  before_action :restrict_access_admin

  def metrics
    metrics = [[],[],0,nil,nil,[],0,nil,nil,0,0,0]
    # Allow duplicate names in hashes
    # Initialize hash of Vice names to 0
    a = Vice.all.map(&:name)
    vices = Hash[a.zip Array.new(a.count,0)]
    # Initialize hash of invest percentages to 0
    a = [0,5,10,15,20]
    percentages = Hash[a.zip Array.new(a.count,0)]
    User.all.each do |u|
      # savings per user
      metrics[0].push [u.fname+' '+u.lname, u.fund.amount_invested.round(2)]
      # savings per month per user
      d1 = u.created_at
      d2 = Date.current
      months = (d2.year * 12 + d2.month) - (d1.year * 12 + d1.month)
      # adjust for different months that are only a few days appart
      months -= (d2.day >= d1.day ? 0 : 1)
      savings_per_month = (months>0) ? u.fund.amount_invested/months : 0
      metrics[1].push [u.fname+' '+u.lname, savings_per_month.round(2)]
      # average savings per month
      metrics[2] += u.fund.amount_invested
      metrics[10] += (savings_per_month)
      if u.fund.amount_invested > 0
        metrics[9] += 1
        metrics[11] += savings_per_month
      end
      # popular vices
      u.vices.map(&:name).each { |n| vices[n] += 1 }
      # folks whose accounts were tracking
      tracking_arr = u.accounts.map(&:tracking)
      metrics[5].push [u.fname+' '+u.lname, tracking_arr]
      # # of folks whose accounts were tracking
      metrics[6] += 1 if tracking_arr.include?(true)
      # percentage being chosen
      percentages[u.invest_percent] += 1
    end
    # average savings
    metrics[3] = metrics[2]
    metrics[2] /= User.all.count
    metrics[3] /= metrics[9]
    metrics[10] /= User.all.count
    metrics[11] /= metrics[9]
    # popular vices
    metrics[4] = vices
    metrics[7] = percentages
    # # of users
    metrics[8] = User.all.count
    json = {
      "savings per user" => metrics[0],
      "savings per month per user" => metrics[1],
      "average savings" => metrics[2].round(2),
      "average savings (excluding non-savers)" => metrics[3].round(2),
      "popular vices" => metrics[4],
      "folks whose accounts were tracking" => metrics[5],
      "# of folks whose accounts were tracking" => metrics[6],
      "percentage being chosen" => metrics[7],
      "# of users" => metrics[8],
      "# of users who have saved money" => metrics[9],
      "average savings per month" => metrics[10].round(2),
      "average savings per month (excluding non-savers)" => metrics[11].round(2)
    }
    render json: json, status: :ok
  end
end
