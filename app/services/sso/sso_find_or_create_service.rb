module Sso
  class SsoFindOrCreateService
    def self.call(provider:, uid:, email:, name:)
      identity = ProviderIdentity.find_by(provider: provider, uid: uid)
      return identity.user if identity

      ActiveRecord::Base.transaction do
        user = User.find_by(email: email.downcase) || build_sso_user(email: email, name: name)
        user.save! if user.new_record?
        user.provider_identities.create!(provider: provider, uid: uid)
        user
      end
    end

    def self.build_sso_user(email:, name:)
      user = User.new(email: email, name: name)
      user.skip_password_validation = true
      user
    end
    private_class_method :build_sso_user
  end
end
