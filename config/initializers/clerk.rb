if (secret_key = ENV["CLERK_SECRET_KEY"]).present?
  Clerk.configure do |c|
    c.secret_key = secret_key
  end
end
