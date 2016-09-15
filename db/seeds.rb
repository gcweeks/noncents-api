# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

vice_names = %w(Nightlife Restaurants Shopping FastFood CoffeeShops Travel
                Experiences Electronics PersonalCare Movies RideSharing)
vice_names.each do |name|
  Vice.create(name: name)
end

user = User.new(fname: 'Cash', lname: 'Money', dob: '1990-01-20',
                phone: '5555552016', invest_percent: 10,
                password: 'Ca5hM0n3y', email: 'cashmoney@gmail.com')
user.create_fund
user.generate_token
user.address = Address.new(line1: '123 Cashmoney Lane', line2: 'Apt 420',
                           city: 'Los Angeles', state: 'CA', zip: '90024')
user.save!
# Log user token for quicker testing
p user.token
