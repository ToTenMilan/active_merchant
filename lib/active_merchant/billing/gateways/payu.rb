module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PayuGateway < Gateway
      self.test_url = 'https://secure.snd.payu.com/api/v2_1/orders'
      self.live_url = 'https://secure.payu.com/api/v2_1/orders'
      AUTH_TEST_URL = 'https://secure.snd.payu.com/pl/standard/user/oauth/authorize'
      AUTH_LIVE_URL = 'https://secure.payu.com/pl/standard/user/oauth/authorize'

      self.supported_countries = ['PL', 'SK', 'CZ']
      self.default_currency = 'PLN'
      self.money_format = :dollars
      self.supported_cardtypes = [:visa, :master]

      self.homepage_url = 'https://www.payu.pl/'
      self.display_name = 'PayU'

      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options={})
        requires!(options, :client_id, :client_secret)
        super
      end

      # http://developers.payu.com/en/restapi.html?__hstc=193375922.94e336152fe355674d2732f9ee2242d6.1585648649330.1585760422483.1585817235493.5&__hssc=193375922.1.1585817235493&__hsfp=2001441357#api_parameters

    #   {
    #     ############# REQUIRED ####################
    #     "customerIp": "127.0.0.1",        #### add_customer_data    (Required)
    #     "merchantPosId": "145227",        #### add_transaction_data     (Required)
    #     "description": "RTV market",         #### add_invoice    (Required)
    #     "currencyCode": "PLN",               #### add_invoice    (Required)
    #     "totalAmount": "15000",              #### add_invoice    (Required)
    #     "settings":{
    #       "invoiceDisabled":"true"
    #     },
    #     "products": [                        #### add_order    (Required)
    #        {
    #           "name": "Wireless Mouse for Laptop",
    #           "unitPrice": "15000",
    #           "quantity": "1"
    #        }
    #     ]
    ################ NOT REQUIRED, STRONGLY RECOMMENDED ###############
    #     "buyer": {                            #### add_customer_data (Not required but recommended, because otherwise buyer will need to pass his data in PayU)
    #       "email": "john.doe@example.com",
    #       "phone": "654111654",
    #       "firstName": "John",
    #       "lastName": "Doe",
    #       "language": "en"
    #     },
    ############### NOT REQUIRED #########################
    #     "notifyUrl": "https://your.eshop.com/notify",     #### add_transaction_data
    #     "extOrderId":"h16zqaf8biafelklutumc3",            #### add_order
    #  }

      def purchase(money, payment, options={})
        post = {}
        add_auth(post)#, options)
        add_transaction_elements(post, options)
        add_invoice(post, money, options)
        add_payment(post, payment)
        # add_address(post, payment, options)
        # add_customer_data(post, options)
        binding.pry
        commit('sale', post)
      end

      def authorize(money, payment, options={})
        post = {}
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, payment, options)
        add_customer_data(post, options)

        commit('authonly', post)
      end

      def capture(money, authorization, options={})
        commit('capture', post)
      end

      def refund(money, authorization, options={})
        commit('refund', post)
      end

      def void(authorization, options={})
        commit('void', post)
      end

      def verify(credit_card, options={})
        MultiResponse.run(:use_first_response) do |r|
          r.process { authorize(100, credit_card, options) }
          r.process(:ignore_result) { void(r.authorization, options) }
        end
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript
      end

      private

      def add_auth(post)#, options)
        post[:grant_type] = 'client_credentials'
        post[:client_id] = @options[:client_id]
        post[:client_secret] = @options[:client_secret]
      end

      def add_customer_data(post, options)
      end

      def add_address(post, creditcard, options)
      end

      def add_invoice(post, money, options)
        post[:amount] = amount(money)
        post[:currency] = (options[:currency] || currency(money))
      end

      def add_payment(post, payment)
      end

      def parse(body)
        binding.pry
        JSON.parse(body)
      end

      def commit(action, parameters)
        auth_url = (test? ? AUTH_TEST_URL : AUTH_LIVE_URL)
        url = (test? ? test_url : live_url)
        # binding.pry
        auth_hash = parse(ssl_post(auth_url, auth_post_data(parameters)))#post_data(action, parameters), {'Content-Type' => 'application/x-www-form-urlencoded'}))
        binding.pry

        response = parse(ssl_post(url, post_data(action, parameters)))

        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          avs_result: AVSResult.new(code: response["some_avs_response_key"]),
          cvv_result: CVVResult.new(response["some_cvv_response_key"]),
          test: test?,
          error_code: error_code_from(response)
        )
      end

      def success_from(response)
      end

      def message_from(response)
      end

      def authorization_from(response)
      end

      def auth_post_data(parameters)
        "grant_type=#{parameters[:grant_type]}" \
        "&client_id=#{parameters[:client_id]}" \
        "&client_secret=#{parameters[:client_secret]}"
      end

      def post_data(action, parameters = {})
        binding.pry
        parameters.merge(sandbox: test?).to_json
        # parameters.to_json
      end

      def error_code_from(response)
        unless success_from(response)
          # TODO: lookup error code for this response
        end
      end
    end
  end
end
