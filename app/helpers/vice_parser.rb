module ViceParser
  # Given category, subcategory, and sub-subcategory, determine which vice this
  # transaction applies to, or return nil if it applies to none
  def get_vice(cat1, cat2, cat3)
    return nil unless cat1
    if cat1 == 'Food and Drink'
      return Vice.find_by(name: 'Nightlife') if cat2 == 'Bar'
      if cat2 == 'Nightlife'
        return Vice.find_by(name: 'Nightlife') unless cat3
        if ['Night Clubs', 'Karaoke', 'Jazz and Blues Cafe',
            'Hookah Lounges'].include? cat3
          return Vice.find_by(name: 'Nightlife')
        end
      elsif cat2 == 'Restaurants'
        if %w(Winery Distillery).include? cat3
          return Vice.find_by(name: 'Nightlife')
        elsif ['Coffee Shop', 'Cafe'].include? cat3
          return Vice.find_by(name: 'CoffeeShops')
        elsif cat3 == 'Fast Food'
          return Vice.find_by(name: 'FastFood')
        end
        return Vice.find_by(name: 'Restaurants')
      end
    elsif cat1 == 'Recreation'
      if ['Go Carts', 'Gun Ranges', 'Hot Air Balloons', 'Hunting and Fishing',
          'Miniature Golf', 'Paintball', 'Skydiving', 'Zoo'].include? cat2
        return Vice.find_by(name: 'Experiences')
      elsif cat2 == 'Arts and Entertainment'
        if ['Theatrical Productions', 'Symphony and Opera', 'Sports Venues',
            'Music and Show Venues', 'Fairgrounds and Rodeos', 'Entertainment',
            'Circuses and Carnivals', 'Bowling',
            'Arcades and Amusement Parks'].include? cat3
          return Vice.find_by(name: 'Experiences')
        elsif ['Dance Halls and Saloons', 'Casinos and Gaming',
               'Billiards and Pool'].include? cat3
          return Vice.find_by(name: 'Nightlife')
        elsif cat3 == 'Movie Theatres'
          return Vice.find_by(name: 'Movies')
        end
      end
    elsif cat1 == 'Service'
      if cat2 == 'Personal Care'
        if ['Tattooing', 'Tanning Salons', 'Spas', 'Piercing',
            'Massage Clinics and Therapists', 'Manicures and Pedicures',
            'Hair Salons and Barbers', 'Hair Removal'].include? cat3
          return Vice.find_by(name: 'PersonalCare')
        end
      end
    elsif cat1 == 'Shops'
      return Vice.find_by(name: 'Shopping') unless cat2
      if ['Adult', 'Antiques', 'Arts and Crafts', 'Auctions', 'Beauty Products',
          'Bicycles', 'Bookstores', 'Cards and Stationery', 'Children',
          'Clothing and Accessories', 'Costumes', 'Dance and Music',
          'Department Stores', 'Digital Purchase', 'Discount Stores',
          'Flea Markets', 'Florists', 'Furniture and Home Decor',
          'Gift and Novelty', 'Hobby and Collectibles', 'Jewelry and Watches',
          'Luggage', 'Music, Video and DVD', 'Musical Instruments', 'Outlet',
          'Pawn Shops', 'Shopping Centers and Malls', 'Sporting Goods',
          'Tobacco', 'Toys', 'Vintage and Thrift',
          'Wedding and Bridal'].include? cat2
        return Vice.find_by(name: 'Shopping')
      elsif cat2 == 'Computers and Electronics'
        return Vice.find_by(name: 'Electronics')
      elsif cat2 == 'Convenience Stores'
        return Vice.find_by(name: 'FastFood')
      end
    elsif cat1 == 'Travel'
      return Vice.find_by(name: 'Travel') unless cat2
      if ['Airlines and Aviation Services', 'Airports', 'Boat', 'Bus Stations',
          'Car and Truck Rentals', 'Charter Buses', 'Cruises', 'Heliports',
          'Limos and Chauffeurs', 'Lodging'].include? cat2
        return Vice.find_by(name: 'Travel')
      elsif cat2 == 'Car Service'
        return Vice.find_by(name: 'Travel') unless cat3
        return Vice.find_by(name: 'RideSharing') if cat3 == 'Ride Share'
      elsif cat2 == 'Taxi'
        return Vice.find_by(name: 'RideSharing')
      end
    end
    nil
  end
end
