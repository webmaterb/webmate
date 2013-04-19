module Webmate::Authentication
  class Responder < Webmate::Responders::Base

    # invoked by
    # POST /users/sessions/token
    def login
      puts "params in login actions: #{params.inspect}"

      {}
    end

    # method invoked by url
    # GET /users/sessions/token
    # GET /users/sessions ?
    def token
      current_user = OpenStruct.new({ id: 123 })

      if nil && current_user
        auth_token = generate_auth_token
        store_token(current_user, auth_token)

        { token: auth_token }.to_json
      else
        @status = 401 # not unauthorized
        {}
      end

    end

    private

    def redis
      @@redis ||= EM::Hiredis.connect
    end

    def generate_auth_token
      SecureRandom.hex
    end

    def store_token(user, token)
      redis.write(token_place_for(user), token)
    end

    def token_place_for(user)
      "some-secret-string-#{user.id}"
    end
  end
end
