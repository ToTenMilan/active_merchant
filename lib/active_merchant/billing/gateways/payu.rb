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
        requires!(options, :merchant_pos_id, :second_key, :client_id, :client_secret)
        super
      end

      # http://developers.payu.com/en/restapi.html?__hstc=193375922.94e336152fe355674d2732f9ee2242d6.1585648649330.1585760422483.1585817235493.5&__hssc=193375922.1.1585817235493&__hsfp=2001441357#api_params

    #   {
    #     ############# REQUIRED ####################
    #     "customerIp": "127.0.0.1",        #### customer_data    (Required)
    #     "merchantPosId": "145227",        #### add_transaction_details     (Required)
    #     "description": "RTV market",         #### add_invoice    (Required)
    #     "currencyCode": "PLN",               #### add_invoice    (Required)
    #     "totalAmount": "15000",              #### add_invoice    (Required)
    #     "settings":{
    #       "invoiceDisabled":"true"
    #     },
    #     "products": [                        #### add_invoice    (Required)
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
    #     "notifyUrl": "https://your.eshop.com/notify",     #### add_transaction_details
    #     "extOrderId":"h16zqaf8biafelklutumc3",            #### add_transaction_details
    #  }

      def purchase(money, payment, params={})
        post = {}
        add_auth(post)#, params)


        # add_transaction_details(post, params)
        post[:merchantPosId] = @options[:merchant_pos_id]
        post[:notifyUrl] = params[:notify_url]
        post[:extOrderId] = params[:ext_order_id]

        # add_invoice(post, money, params)
        post[:description] = params[:description]
        post[:currencyCode] = params[:currency_code]
        post[:totalAmount] = params[:total_amount]
        # binding.pry
        post[:products] = params[:products].map do |position|
          position.transform_keys { |k| k.to_s.camelize(:lower).to_sym }
        end
            # add_payment(post, payment)


            # add_address(post, payment, params)
        # add_customer_data(post, params)
        post[:customerIp] = params[:customer_ip]
        post[:buyer] = params[:buyer].transform_keys { |k| k.to_s.camelize(:lower).to_sym }
        post[:invoiceDisabled] = true if test?
        # binding.pry

        post[:payMethods] = {}
        post[:payMethods][:payMethod] = params[:pay_methods][:pay_method].transform_keys {
          |k| k.to_s.camelize(:lower).to_sym
        }
        commit('sale', post)
      end

      def authorize(money, payment, params={})
        # post = {}
        # add_invoice(post, money, params)
        # add_payment(post, payment)
        # add_address(post, payment, params)
        # add_customer_data(post, params)

        commit('authonly', post)
      end

      def capture(money, authorization, params={})
        commit('capture', post)
      end

      def refund(money, authorization, params={})
        commit('refund', post)
      end

      def void(authorization, params={})
        commit('void', post)
      end

      def verify(credit_card, params={})
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

      def add_auth(post)#, params)
        post[:grant_type] = 'client_credentials'
        post[:client_id] = @options[:client_id]
        post[:client_secret] = @options[:client_secret]
      end

      def add_customer_data(post, params)
      end

      def add_address(post, creditcard, params)
      end

      def add_invoice(post, money, params)
        post[:amount] = amount(money)
        post[:currency] = (params[:currency] || currency(money))
      end

      def add_payment(post, payment)
      end

      def parse(body)
        # binding.pry
        JSON.parse(body)
      end

      def commit(action, params)
        auth_endpoint = (test? ? AUTH_TEST_URL : AUTH_LIVE_URL)
        endpoint = (test? ? test_url : live_url)
        # binding.pry
        auth_hash = parse(ssl_post(auth_endpoint, auth_post_data(params)))#post_data(action, params), {'Content-Type' => 'application/x-www-form-urlencoded'}))
        # binding.pry
        # params = params.delete('client_id').delete('client_secret').delete('grant_type')
        data = post_data(action, params)
        response = parse(ssl_post(endpoint, data, headers(auth_hash)))

        # response.body => "{\"status\":{\"statusCode\":\"SUCCESS\"},
        # \"redirectUri\":\"https://merch-prod.snd.payu.com/info/?orderId=35JM8PGH1L200408GUEST000P01&token=eyJhbGciOiJIUzI1NiJ9.eyJvcmRlcklkIjoiMzVKTThQR0gxTDIwMDQwOEdVRVNUMDAwUDAxIiwicG9zSWQiOiJPSWEwbmR0ciIsImF1dGhvcml0aWVzIjpbIlJPTEVfQ0xJRU5UIl0sInBheWVyRW1haWwiOiJqb2huLmRvZUBleGFtcGxlLmNvbSIsImV4cCI6MTU4NjQzMzMyMiwiaXNzIjoiUEFZVSIsImF1ZCI6ImFwaS1nYXRld2F5Iiwic3ViIjoiUGF5VSBzdWJqZWN0IiwianRpIjoiYWJjZmUxZWUtYWY2Yi00NGYyLTk4NGMtMzdmNzI1MDVkZTIyIn0.avvnMksSWDt9mVbPltx-Ap1_GtjvW5v515DpwMVQnQQ&lang=en\",\"orderId\":\"35JM8PGH1L200408GUEST000P01\"}"
        binding.pry
        # Response.new(
        #   success_from(response),
        #   message_from(response),
        #   response,
        #   test: test?,
        #   error_code: error_code_from(response)
        # )
        # binding.pry
      #   wrap_response(response)
      rescue ResponseError => e
        binding.pry
        if e.response.code == "302"
          # wrap_response(e.response)
          Response.new(
            success_from(e.response),
            message_from(e.response),
            # response,
            test: test?,
            error_code: error_code_from(e.response)
          )
        else
          raise ResponseError.new(e.response)
        end
      end

      def headers(auth_hash)
        {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{auth_hash['access_token']}"
        }
      end

      def wrap_response(response)
        Response.new(
          success_from(response),
          message_from(response),
          response,
          test: test?,
          error_code: error_code_from(response)
        )
      end

      def success_from(response)
        (200..302).cover?(response.code.to_i)
      end

      def message_from(response)
        response = JSON.parse(response.body).with_indifferent_access
        binding.pry
        response[:status][:statusCode]
      end

      def authorization_from(response)
      end

      def auth_post_data(params)
        "grant_type=#{params[:grant_type]}" \
        "&client_id=#{params[:client_id]}" \
        "&client_secret=#{params[:client_secret]}"
      end

      def post_data(action, params = {})
        # binding.pry
        JSON.generate(params.merge(sandbox: test?))
      end

      def error_code_from(response)
        unless success_from(response)
          # TODO: lookup error code for this response
        end
      end
    end
  end
end
