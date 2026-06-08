module TokenIssuable
  private

  def token_response(user)
    refresh = user.refresh_tokens.create!
    {
      access_token:  JwtService.encode(user_id: user.id),
      refresh_token: refresh.token,
      user:          user_json(user)
    }
  end

  def user_json(user)
    user.as_json(only: [ :id, :name, :email, :created_at ])
  end
end
