# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).

vice_names = [
  'Bars/Nightlife',
  'Restaurants',
  'Shopping',
  'Fast Food',
  'Coffee Shops',
  'Travel',
  'Experiences',
  'Electronics',
  'Personal Care',
  'Movies',
  'Ride Sharing'
]
vice_names.each do |name|
  Vice.create(name: name)
end
