# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Platforms
platforms_data = [
  { name: "PlayStation 5", short_name: "PS5", platform_type: "console", manufacturer: "Sony" },
  { name: "Xbox Series X", short_name: "XSX", platform_type: "console", manufacturer: "Microsoft" },
  { name: "Nintendo Switch", short_name: "Switch", platform_type: "console", manufacturer: "Nintendo" },
  { name: "PC", short_name: "PC", platform_type: "pc", manufacturer: nil },
  { name: "PlayStation 4", short_name: "PS4", platform_type: "console", manufacturer: "Sony" },
  { name: "Xbox One", short_name: "XB1", platform_type: "console", manufacturer: "Microsoft" },
  { name: "iOS", short_name: "iOS", platform_type: "mobile", manufacturer: "Apple" },
  { name: "Android", short_name: "Android", platform_type: "mobile", manufacturer: "Google" }
]

puts "Creating platforms..."
platforms_data.each do |data|
  Platform.find_or_create_by!(name: data[:name]) do |platform|
    platform.short_name = data[:short_name]
    platform.platform_type = data[:platform_type]
    platform.manufacturer = data[:manufacturer]
    platform.active = true
  end
end
puts "✓ Created #{Platform.count} platforms"

# Genres
genres_data = [
  { name: "Action", description: "Fast-paced games focusing on physical challenges and hand-eye coordination" },
  { name: "Adventure", description: "Story-driven games focused on exploration and puzzle-solving" },
  { name: "RPG", description: "Role-playing games with character progression and story choices" },
  { name: "Strategy", description: "Games requiring careful planning and tactical thinking" },
  { name: "Simulation", description: "Games that simulate real-world activities" },
  { name: "Sports", description: "Games based on traditional sports and athletics" },
  { name: "Puzzle", description: "Games focused on problem-solving and pattern recognition" },
  { name: "Horror", description: "Games designed to frighten and create tension" },
  { name: "Racing", description: "Games focused on vehicle racing competitions" },
  { name: "Fighting", description: "Games centered on close combat between characters" },
  { name: "Platformer", description: "Games focused on jumping and navigating platforms" },
  { name: "Shooter", description: "Games focused on ranged weapon combat" }
]

puts "Creating genres..."
genres_data.each do |data|
  Genre.find_or_create_by!(name: data[:name]) do |genre|
    genre.description = data[:description]
  end
end
puts "✓ Created #{Genre.count} genres"

# Publishers
publishers_data = [
  { name: "Nintendo", country: "Japan", website_url: "https://www.nintendo.com" },
  { name: "Sony Interactive Entertainment", country: "Japan", website_url: "https://www.sie.com" },
  { name: "Microsoft", country: "United States", website_url: "https://www.microsoft.com" },
  { name: "Electronic Arts", country: "United States", website_url: "https://www.ea.com" },
  { name: "Activision Blizzard", country: "United States", website_url: "https://www.activisionblizzard.com" },
  { name: "Ubisoft", country: "France", website_url: "https://www.ubisoft.com" },
  { name: "Take-Two Interactive", country: "United States", website_url: "https://www.take2games.com" },
  { name: "Bandai Namco", country: "Japan", website_url: "https://www.bandainamcoent.com" }
]

puts "Creating publishers..."
publishers_data.each do |data|
  Publisher.find_or_create_by!(name: data[:name]) do |publisher|
    publisher.country = data[:country]
    publisher.website_url = data[:website_url]
  end
end
puts "✓ Created #{Publisher.count} publishers"

# Developers
developers_data = [
  { name: "Nintendo EPD", country: "Japan", website_url: "https://www.nintendo.com" },
  { name: "Naughty Dog", country: "United States", website_url: "https://www.naughtydog.com" },
  { name: "Rockstar Games", country: "United States", website_url: "https://www.rockstargames.com" },
  { name: "CD Projekt Red", country: "Poland", website_url: "https://www.cdprojektred.com" },
  { name: "FromSoftware", country: "Japan", website_url: "https://www.fromsoftware.jp" },
  { name: "Bethesda Game Studios", country: "United States", website_url: "https://bethesdagamestudios.com" },
  { name: "Insomniac Games", country: "United States", website_url: "https://insomniac.games" },
  { name: "Santa Monica Studio", country: "United States", website_url: "https://sms.playstation.com" }
]

puts "Creating developers..."
developers_data.each do |data|
  Developer.find_or_create_by!(name: data[:name]) do |developer|
    developer.country = data[:country]
    developer.website_url = data[:website_url]
  end
end
puts "✓ Created #{Developer.count} developers"

# Publications (for critic reviews)
publications_data = [
  { name: "IGN", website_url: "https://www.ign.com", credibility_weight: 8.5 },
  { name: "GameSpot", website_url: "https://www.gamespot.com", credibility_weight: 8.0 },
  { name: "Polygon", website_url: "https://www.polygon.com", credibility_weight: 7.5 },
  { name: "Eurogamer", website_url: "https://www.eurogamer.net", credibility_weight: 8.0 },
  { name: "PC Gamer", website_url: "https://www.pcgamer.com", credibility_weight: 7.5 },
  { name: "Kotaku", website_url: "https://www.kotaku.com", credibility_weight: 7.0 }
]

puts "Creating publications..."
publications_data.each do |data|
  Publication.find_or_create_by!(name: data[:name]) do |publication|
    publication.website_url = data[:website_url]
    publication.credibility_weight = data[:credibility_weight]
  end
end
puts "✓ Created #{Publication.count} publications"

puts "✅ Database seeding complete!"
