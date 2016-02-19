# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).

vice_names = %w(Nightlife Restaurants Shopping FastFood CoffeeShops Travel
                Experiences Electronics PersonalCare Movies RideSharing)
vice_names.each do |name|
  Vice.create(name: name)
end

user = User.new(fname: 'Cash', lname: 'Money', dob: '1990-01-20',
                number: '+15555552016', invest_percent: 10,
                password: 'Ca5hM0n3y', email: 'cashmoney@gmail.com')
user.generate_token!
user.save!
