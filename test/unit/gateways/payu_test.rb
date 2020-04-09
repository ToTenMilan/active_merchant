require 'test_helper'

class PayuTest < Test::Unit::TestCase
  def setup
  ########################### CHANGE BEFORE PUSH ###################
    @gateway = PayuGateway.new(merchant_pos_id: '300746', second_key: '13a980d4f851f3d9a1cfc792fb1f5e50', client_id: '300746', client_secret: '2ee86a66e5d97e3fadc400c9f19b065d')
    @credit_card = credit_card('4444333322221111', verification_value: '123', first_name: 'APPROVED', last_name: '')
    @amount = 100

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
    # @gateway.expects(:ssl_post).returns(successful_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    binding.pry
    assert_equal 'SUCCESS', response.authorization
    assert response.test?
  end

  def test_failed_purchase
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_authorize
  end

  def test_failed_authorize
  end

  def test_successful_capture
  end

  def test_failed_capture
  end

  def test_successful_refund
  end

  def test_failed_refund
  end

  def test_successful_void
  end

  def test_failed_void
  end

  def test_successful_verify
  end

  def test_successful_verify_with_failed_void
  end

  def test_failed_verify
  end

  def test_scrub
    assert @gateway.supports_scrubbing?
    assert_equal @gateway.scrub(pre_scrubbed), post_scrubbed
  end

  private

  def pre_scrubbed
    %q(
      Run the remote tests for this gateway, and then put the contents of transcript.log here.
    )
  end

  def post_scrubbed
    %q(
      Put the scrubbed contents of transcript.log here after implementing your scrubbing function.
      Things to scrub:
        - Credit card number
        - CVV
        - Sensitive authentication details
    )
  end

  def successful_purchase_response
    %(
      Easy to capture by setting the DEBUG_ACTIVE_MERCHANT environment variable
      to "true" when running remote tests:

      $ DEBUG_ACTIVE_MERCHANT=true ruby -Itest \
        test/remote/gateways/remote_payu_test.rb \
        -n test_successful_purchase
    )
  end

  def failed_purchase_response
  end

  def successful_authorize_response
  end

  def failed_authorize_response
  end

  def successful_capture_response
  end

  def failed_capture_response
  end

  def successful_refund_response
  end

  def failed_refund_response
  end

  def successful_void_response
  end

  def failed_void_response
  end
end
