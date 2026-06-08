# Idempotent — safe to run on every container start.
# Creates two demo users with known credentials, a handful of concerts each, and 2 seed images per concert.

SeedFile = Struct.new(:path, :original_filename, :content_type) do
  def read = File.binread(path)
end

puts "Seeding demo users..."

alice = User.find_or_create_by!(email: "alice@lumen.dev") do |u|
  u.name     = "Alice"
  u.clerk_id = "seed_alice"
end

bob = User.find_or_create_by!(email: "bob@lumen.dev") do |u|
  u.name     = "Bob"
  u.clerk_id = "seed_bob"
end

puts "Seeding concerts..."

concerts = [
  {
    user:         alice,
    name:         "Radiohead — In Rainbows Tour",
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
    user:         alice,
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
    user:         alice,
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
    user:         bob,
    name:         "Kendrick Lamar — The Big Steppers Tour",
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
    user:         bob,
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
    user:         bob,
    name:         "Massive Attack — Mezzanine XX1 Tour",
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
  Event.find_or_create_by!(user: attrs[:user], name: attrs[:name], date: attrs[:date]) do |e|
    e.assign_attributes(attrs.except(:user))
  end
end

puts "Seeding media..."

image_path = Rails.root.join("db/seeds/images/concert.jpg")

Event.all.each do |event|
  next if event.media.exists?

  2.times do |i|
    file = SeedFile.new(image_path, "photo#{i + 1}.jpg", "image/jpeg")
    key  = S3UploadService.upload(file: file, user_id: event.user_id, event_id: event.id)
    event.media.create!(user: event.user, path: key)
  end
end

puts "Done. Seeded alice@lumen.dev and bob@lumen.dev."
