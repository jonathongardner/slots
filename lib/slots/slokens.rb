# frozen_string_literal: true

require 'jwt'
module Slots
  class Slokens
    attr_reader :token, :exp, :iat, :extra_payload, :authentication_model_values
    def initialize(decode: false, encode: false, token: nil, authentication_record: nil, extra_payload: nil)
      if decode
        decode(token)
      elsif encode
        @authentication_model_values = authentication_record.as_json
        @extra_payload = extra_payload.as_json
        encode()
        @valid = true
      else
        raise 'must encode or decode'
      end
    end
    def self.decode(token)
      self.new(decode: true, token: token)
    end
    def self.encode(authentication_record, extra_payload)
      self.new(encode: true, authentication_record: authentication_record, extra_payload: extra_payload)
    end

    def expired?
      @expired
    end

    def valid?
      @valid
    end

    def valid!
      raise InvalidToken, "Invalid Token" unless valid?
      self
    end

    def update_token
      encode
    end

    def session
      @extra_payload['session']
    end

    def payload
      {
        authentication_model_key => @authentication_model_values,
        'exp' => @exp,
        'iat' => @iat,
        'extra_payload' => @extra_payload,
      }
    end

    private
      def authentication_model_key
        Slots.configuration.authentication_model.name.underscore
      end

      def default_expected_keys
        ['exp', 'iat', authentication_model_key]
      end
      def secret
        Slots.configuration.secret(@iat)
      end
      def encode
        @exp = Slots.configuration.token_lifetime.from_now.to_i
        @iat = Time.now.to_i
        @token = JWT.encode self.payload, secret, 'HS256'
        @expired = false
        @valid = true
      end

      def decode(token)
        @token = token
        begin
          set_payload
          JWT.decode @token, secret, true, verify_iat: true, algorithm: 'HS256'
        rescue JWT::ExpiredSignature
          @expired = true
        rescue JWT::InvalidIatError, JWT::VerificationError, JWT::DecodeError, Slots::InvalidSecret, NoMethodError, JSON::ParserError
          @valid = false
        else
          @valid = payload.slice(*default_expected_keys).compact.length == default_expected_keys.length
        end
      end

      def set_payload
        encoded64 = @token.split('.')[1] || ''
        string_payload = Base64.decode64(encoded64)
        local_payload = JSON.parse(string_payload)
        raise JSON::ParserError unless local_payload.is_a?(Hash)
        @exp = local_payload['exp']&.to_i
        @iat = local_payload['iat']&.to_i
        @authentication_model_values = local_payload[authentication_model_key]
        @extra_payload = local_payload['extra_payload']
      end
  end
end