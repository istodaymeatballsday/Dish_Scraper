require 'httparty'
require 'mongo'

def dishes
  body = JSON.parse(HTTParty.get('http://carbonateapiprod.azurewebsites.net/api/v1/mealprovidingunits/3d519481-1667-4cad-d2a3-08d558129279/dishoccurrences?startDate=2018-01-01&endDate=2020-01-01').body)
  foods = []
  all_ingredients = []
  i = 0
  body.each do |dish|
    next if dish['displayNames'].count.zero?

    dish_name = (dish['displayNames'][1] || dish['displayNames'][0])['dishDisplayName']
    next if /closed|stängt/i =~ dish_name

    date = dish['startDate'].split[0]
    ingredients = get_ingredients(dish_name)
    all_ingredients << ingredients
    foods << {
      name: dish_name,
      timestamp: Time.strptime(date, '%m/%d/%Y').to_i,
      ingredients: ingredients,
      meta: { createdAt: Time.now.to_i },
      vegan: vegan?(dish)
    }
    i += 1
  end
  [foods, all_ingredients
    .flatten
    .uniq
    .map { |ingredient| { name: ingredient } }]
end

def vegan?(dish)
  return false if !dish || !dish.key?('dishType') || dish['dishType'].nil?

  return true if /vegan/i =~ dish['dishType']['dishTypeName']

  false
end

def get_ingredients(dish_name)
  puts dish_name
  dish_name.downcase.split(/\s*,\s*|\s*&\s*/)
           .sort { |a, b| a <=> b }
end

def add_to_food_db(collection_name, docs)
  client = Mongo::Client.new(['localhost:27017'], database: 'food')
  collection = client[collection_name]
  collection.insert_many(docs)
end
# database

def ingredients_from_db
  client = Mongo::Client.new(['localhost:27017'], database: 'food')
  collection = client[:ingredients]
  ingredients = []
  collection.find(iid: { '$exists': false })
            .each { |doc| ingredients << doc['name'] }
  ingredients
end

def dishes_from_db
  client = Mongo::Client.new(['localhost:27017'], database: 'food')
  collection = client[:dishes]
  dishes = []
  collection.find(dish: /Meatball/).each { |doc| dishes << doc['_id'] }
  dishes
end

all_dishes = dishes
puts all_dishes[0].sort_by { |a| a[:dish] }

# arr = [1, 2]
# puts arr[0] || arr[1]

# arr = [1]
# a = arr[1] ? 1 : 2
# puts a

# addToFoodDB(:dishes, dishes[0])
# addToFoodDB(:ingredients, dishes[1])
# addToFoodDB(:dishes, dishes[0])
# addToFoodDB(:ingredients, dishes[1])

# file = File.read('filename')[1..-1].chop.split(/\s*,\s*/)
# get_ingredients('Bean otto, green asparagus & pesto', [])
