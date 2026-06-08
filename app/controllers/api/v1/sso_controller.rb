class Api::V1::SsoController < ApplicationController
  include TokenIssuable

  def google
    profile = Sso::GoogleSsoService.call(params.fetch(:id_token))
    render json: token_response(find_or_create(profile, "google"))
  end

  private

  def find_or_create(profile, provider)
    Sso::SsoFindOrCreateService.call(
      provider: provider,
      uid:      profile[:sub],
      email:    profile[:email],
      name:     profile[:name].presence || profile[:email].split("@").first
    )
  end
end
