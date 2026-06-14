# Idempotent — safe to run on every container start.
# Creates the demo user (bob) and seeds concerts + photos for them.

puts "Seeding demo user..."

bob = User.find_or_create_by!(clerk_id: "user_3F8idHXdn62zkU16X76eBvIXEz4") do |u|
  u.name  = "Bobbie"
  u.email = "bob@lumen.dev"
end

puts "Seeding concerts..."

concerts = [
  {
    name:         "Radiohead",
    date:         "2008-05-26",
    country_name: "Denmark",
    country_code: "DK",
    city:         "Roskilde",
    full_address: "Roskilde Festival, Darupvej 29, 4000 Roskilde, Denmark",
    address:      "Roskilde Festival, Darupvej 29",
    feature_type: "venue",
    lat:          55.6199,
    lng:          12.0832,
    note:         "Front row. Creep encore. Life changing."
  },
  {
    name:         "Nick Cave & The Bad Seeds",
    date:         "2023-09-14",
    country_name: "Denmark",
    country_code: "DK",
    city:         "Copenhagen",
    full_address: "Royal Arena, Ørestads Blvd. 50, 2300 Copenhagen, Denmark",
    address:      "Royal Arena, Ørestads Blvd. 50",
    feature_type: "arena",
    lat:          55.6370,
    lng:          12.5785,
    note:         "First show after the loss of his son. Utterly moving."
  },
  {
    name:         "Bon Iver",
    date:         "2022-07-01",
    country_name: "Norway",
    country_code: "NO",
    city:         "Oslo",
    full_address: "Øyafestivalen, Tøyenparken, Oslo, Norway",
    address:      "Tøyenparken",
    feature_type: "festival",
    lat:          59.9175,
    lng:          10.7700,
    note:         "Skinny Love still hits different live."
  },
  {
    name:         "Kendrick Lamar",
    date:         "2022-11-17",
    country_name: "Sweden",
    country_code: "SE",
    city:         "Stockholm",
    full_address: "Avicii Arena, Globentorget 2, 121 77 Stockholm, Sweden",
    address:      "Avicii Arena, Globentorget 2",
    feature_type: "arena",
    lat:          59.2933,
    lng:          18.0832,
    note:         "N95 and Humble back to back. The crowd lost it."
  },
  {
    name:         "PJ Harvey",
    date:         "2016-09-03",
    country_name: "United Kingdom",
    country_code: "GB",
    city:         "London",
    full_address: "Hammersmith Apollo, 45 Queen Caroline St, London, United Kingdom",
    address:      "Hammersmith Apollo, 45 Queen Caroline St",
    feature_type: "venue",
    lat:          51.4927,
    lng:          -0.2258,
    note:         "The Hope Six Demolition Project tour. Raw and political."
  },
  {
    name:         "Massive Attack",
    date:         "2019-04-13",
    country_name: "Germany",
    country_code: "DE",
    city:         "Berlin",
    full_address: "Tempodrom, Möckernstraße 10, 10963 Berlin, Germany",
    address:      "Tempodrom, Möckernstraße 10",
    feature_type: "venue",
    lat:          52.4995,
    lng:          13.3789,
    note:         "Teardrop with visuals. Goosebumps the whole set."
  }
]

concerts.each do |attrs|
  Event.find_or_create_by!(user: bob, name: attrs[:name], date: attrs[:date]) do |e|
    e.assign_attributes(attrs)
  end
end

puts "Seeding media..."

image_path = Rails.root.join("db/seeds/images/concert.jpg")

bob.events.each do |event|
  next if event.media.exists?

  2.times do |i|
    medium = event.media.create!(user: bob)
    medium.photo.attach(
      io:           File.open(image_path),
      filename:     "photo#{i + 1}.jpg",
      content_type: "image/jpeg"
    )
  end
end

puts "Done. Seeded 6 concerts for #{bob.name} (#{bob.clerk_id})."
