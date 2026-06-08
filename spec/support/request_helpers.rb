module RequestHelpers
  def auth_headers(user)
    clerk_double = double(
      "ClerkProxy",
      user: double(
        "ClerkUser",
        id:              user.clerk_id,
        first_name:      user.name,
        last_name:       nil,
        email_addresses: [ double("EmailAddress", email_address: user.email) ]
      )
    )
    allow_any_instance_of(ApplicationController).to receive(:clerk).and_return(clerk_double)
    { "Authorization" => "Bearer fake-clerk-token" }
  end

  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
