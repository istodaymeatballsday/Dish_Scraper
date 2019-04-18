require 'httparty'
require 'mongo'

def getDishes
	response = HTTParty.get('http://carbonateapiprod.azurewebsites.net/api/v1/mealprovidingunits/3d519481-1667-4cad-d2a3-08d558129279/dishoccurrences?startDate=2016-04-17&endDate=2019-04-25')
	foods = []
	allIngredients = []
	body = JSON.parse(response.body)
	i = -1
	body.each do |dish| 
		date = dish['startDate'].split[0]
		dish['displayNames'].each do |dishLang|
			next if (dishLang["displayNameCategory"]["displayNameCategoryName"] == "Swedish" || /^Closed/ =~ dishLang['dishDisplayName'])
			i+=1
			ingredients = getIngredients(dishLang['dishDisplayName'], ingredients).map {|ingredient| ingredient.downcase }.sort {|a,b| a <=> b}
			allIngredients << ingredients
			foods << {'dish' => dishLang['dishDisplayName'], 'timestamp' => Time.strptime(date, "%m/%d/%Y").to_i, 'ingredients' => ingredients, 'meta' => {"createdAt" => Time.now.to_i } }
		end
	end
	return foods, allIngredients.flatten.uniq.sort {|a,b| a <=> b}
end

def getIngredients(dish, ingredientsList)
	dish.downcase.split(/\s*,\s*|\s*&\s*/)
end

def database
	client = Mongo::Client.new([ 'localhost:27017' ], :database => 'food')
	db = client.database
	dishesAndAllIngredients = getDishes
	foodsCollection = client[:dishes]
	res1 = foodsCollection.insert_many(dishesAndAllIngredients[0])
	ingredientsCollection = client[:ingredients]
	res2 = ingredientsCollection.insert_many(dishesAndAllIngredients[1].map {|ingredient| {"name" => ingredient}})
	puts res1.n
	puts res2.n
end
database

# file = File.read('filename')[1..-1].chop.split(/\s*,\s*/)
# getIngredients('Bean otto, green asparagus & pesto', [])
