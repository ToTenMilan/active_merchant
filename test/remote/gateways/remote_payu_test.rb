require 'test_helper'

class RemotePayuTest < Test::Unit::TestCase
  def setup
    ########################### CHANGE BEFORE PUSH ###################
      # @gateway = PayuGateway.new(merchant_pos_id: '382705', second_key: 'de5c5d9c49b981ae827528ef34ed8034', client_id: '382705', client_secret: 'ac1c82652fe0eac71e091e1070b84d4a')
      @gateway = PayuGateway.new(fixtures(:payu))
      @credit_card = credit_card('4444333322221111', verification_value: '123', first_name: 'APPROVED', last_name: '')

      @options = {
        # Required
        customer_ip: '127.0.0.1',
        # order_id: generate_unique_id,
        # billing_address: address,
        description: 'Store Purchase',
        currency_code: 'PLN',
        total_amount: '21000',
        products: [
          {
            name: 'Wireless Mouse for Laptop',
            unit_price: '15000',
            quantity: '1'
          },
          {
            name: "HDMI cable",
            unit_price: "6000",
            quantity: "1"
          }
        ],
        # strongly recommended
        buyer: {
          email: "john.doe@example.com",
          phone: "654111654",
          first_name: "John",
          last_name: "Doe",
          language: "en"
        },
        # optional
        notify_url: 'https://www.example.com/notify',
        ext_order_id: Time.now.to_i,
        pay_methods: {
          pay_method: {
            type: "PBL",
            value: 'm'
          }
        }
      }
    end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'SUCCESS', response.message
  end

  def test_successful_purchase_with_more_options
    options = {
      order_id: '1',
      ip: "127.0.0.1",
      email: "joe@example.com"
    }

    response = @gateway.purchase(@amount, @credit_card, options)
    assert_success response
    assert_equal 'REPLACE WITH SUCCESS MESSAGE', response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'REPLACE WITH FAILED PURCHASE MESSAGE', response.message
  end

  def test_successful_authorize_and_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    assert capture = @gateway.capture(@amount, auth.authorization)
    assert_success capture
    assert_equal 'REPLACE WITH SUCCESS MESSAGE', capture.message
  end

  def test_failed_authorize
    response = @gateway.authorize(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'REPLACE WITH FAILED AUTHORIZE MESSAGE', response.message
  end

  def test_partial_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    assert capture = @gateway.capture(@amount-1, auth.authorization)
    assert_success capture
  end

  def test_failed_capture
    response = @gateway.capture(@amount, '')
    assert_failure response
    assert_equal 'REPLACE WITH FAILED CAPTURE MESSAGE', response.message
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    assert refund = @gateway.refund(@amount, purchase.authorization)
    assert_success refund
    assert_equal 'REPLACE WITH SUCCESSFUL REFUND MESSAGE', refund.message
  end

  def test_partial_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    assert refund = @gateway.refund(@amount-1, purchase.authorization)
    assert_success refund
  end

  def test_failed_refund
    response = @gateway.refund(@amount, '')
    assert_failure response
    assert_equal 'REPLACE WITH FAILED REFUND MESSAGE', response.message
  end

  def test_successful_void
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    assert void = @gateway.void(auth.authorization)
    assert_success void
    assert_equal 'REPLACE WITH SUCCESSFUL VOID MESSAGE', void.message
  end

  def test_failed_void
    response = @gateway.void('')
    assert_failure response
    assert_equal 'REPLACE WITH FAILED VOID MESSAGE', response.message
  end

  def test_successful_verify
    response = @gateway.verify(@credit_card, @options)
    assert_success response
    assert_match %r{REPLACE WITH SUCCESS MESSAGE}, response.message
  end

  def test_failed_verify
    response = @gateway.verify(@declined_card, @options)
    assert_failure response
    assert_match %r{REPLACE WITH FAILED PURCHASE MESSAGE}, response.message
  end

  def test_invalid_login
    gateway = PayuGateway.new(login: '', password: '')

    response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_match %r{REPLACE WITH FAILED LOGIN MESSAGE}, response.message
  end

  def test_dump_transcript
    # This test will run a purchase transaction on your gateway
    # and dump a transcript of the HTTP conversation so that
    # you can use that transcript as a reference while
    # implementing your scrubbing logic.  You can delete
    # this helper after completing your scrub implementation.
    dump_transcript_and_fail(@gateway, @amount, @credit_card, @options)
  end

  def test_transcript_scrubbing
    transcript = capture_transcript(@gateway) do
      @gateway.purchase(@amount, @credit_card, @options)
    end
    transcript = @gateway.scrub(transcript)

    assert_scrubbed(@credit_card.number, transcript)
    assert_scrubbed(@credit_card.verification_value, transcript)
    assert_scrubbed(@gateway.options[:password], transcript)
  end

end
