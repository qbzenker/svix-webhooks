# frozen_string_literal: true

require "svix"

DEFAULT_MSG_ID = "msg_p5jXN8AQM9LWM0D4loKWxJek"
DEFAULT_PAYLOAD = '{"test": 2432232314}'
DEFAULT_SECRET = "MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw"
TOLERANCE = 5 * 60

class TestPayload

    def initialize(timestamp = Time.now.to_i)
        @secret = DEFAULT_SECRET

        @id = DEFAULT_MSG_ID
        @timestamp = timestamp

        @payload = DEFAULT_PAYLOAD
        @secret = DEFAULT_SECRET

        toSign = "#{@id}.#{@timestamp}.#{@payload}"
        @signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), Base64.decode64(DEFAULT_SECRET), toSign)).strip

        @headers = {
            "svix-id" => @id,
            "svix-signature" => "v1,#{@signature}",
            "svix-timestamp" => @timestamp
        }
    end

    attr_accessor :secret
    attr_accessor :id
    attr_accessor :timestamp
    attr_accessor :payload
    attr_accessor :signature
    attr_accessor :headers
end

describe Svix::Webhook do
    it "missing id raises error" do
        testPayload = TestPayload.new
        testPayload.headers.delete("svix-id")

        wh = Svix::Webhook.new(testPayload.secret)

        expect { wh.verify(testPayload.payload, testPayload.headers) }.to raise_error(Svix::WebhookVerificationError)
    end

    it "missing timestamp raises error" do
        testPayload = TestPayload.new
        testPayload.headers.delete("svix-timestamp")

        wh = Svix::Webhook.new(testPayload.secret)

        expect { wh.verify(testPayload.payload, testPayload.headers) }.to raise_error(Svix::WebhookVerificationError)
    end

    it "missing signature raises error" do
        testPayload = TestPayload.new
        testPayload.headers.delete("svix-signature")

        wh = Svix::Webhook.new(testPayload.secret)

        expect { wh.verify(testPayload.payload, testPayload.headers) }.to raise_error(Svix::WebhookVerificationError)
    end

    it "invalid signature raises error" do
        testPayload = TestPayload.new
        testPayload.headers["svix-signature"] = "v1,g0hM9SsE+OTPJTGt/tmIKtSyZlE3uFJELVlNIOLawdd"

        wh = Svix::Webhook.new(testPayload.secret)

        expect { wh.verify(testPayload.payload, testPayload.headers) }.to raise_error(Svix::WebhookVerificationError)
    end

    it "valid signature is valid and returns valid json" do
        testPayload = TestPayload.new
        wh = Svix::Webhook.new(testPayload.secret)

        json = wh.verify(testPayload.payload, testPayload.headers)
        expect(json[:test]).to eq(2432232314)
    end

    it "old timestamp raises error" do
        testPayload = TestPayload.new(Time.now.to_i - TOLERANCE - 1)

        wh = Svix::Webhook.new(testPayload.secret)

        expect { wh.verify(testPayload.payload, testPayload.headers) }.to raise_error(Svix::WebhookVerificationError)
    end

    it "new timestamp raises error" do
        testPayload = TestPayload.new(Time.now.to_i + TOLERANCE + 1)

        wh = Svix::Webhook.new(testPayload.secret)

        expect { wh.verify(testPayload.payload, testPayload.headers) }.to raise_error(Svix::WebhookVerificationError)
    end

    it "invalid timestamp raises error" do
        testPayload = TestPayload.new("teadwd")

        wh = Svix::Webhook.new(testPayload.secret)

        expect { wh.verify(testPayload.payload, testPayload.headers) }.to raise_error(Svix::WebhookVerificationError)
    end
end