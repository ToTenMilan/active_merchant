require 'net/http'
require 'uri'
require 'json'
require "addressable/uri"
require 'active_support/all'

# api_url = 'https://secure.snd.payu.com/api/v2_1/orders'

# # auth
# auth_hash = Net::HTTP.post(
#   URI('https://secure.snd.payu.com/pl/standard/user/oauth/authorize'),
#   'grant_type=client_credentials&client_id=300746&client_secret=2ee86a66e5d97e3fadc400c9f19b065d'
# )
# # => "{\"access_token\":\"c401ff60-f648-4843-97fc-47962c6ec206\",\"token_type\":\"bearer\",\"expires_in\":43199,\"grant_type\":\"client_credentials\"}"

# token = JSON.parse(auth_hash.response.body)["access_token"]
# pp token # => "1ad1ccfe-daa0-4434-87a0-62f30bca5c7e"




# ##################################################################################
# puts "\n\nbody as normal string with double quotes"
# body = '{
#   "notifyUrl": "https://activemerchant-payu-integration.com/notify",
#   "customerIp": "127.0.0.1",
#   "merchantPosId": "300746",
#   "description": "RTV market",
#   "currencyCode": "PLN",
#   "totalAmount": "21000",
#   "buyer": {
#     "email": "john.doe@example.com",
#     "phone": "654111654",
#     "firstName": "John",
#     "lastName": "Doe",
#     "language": "pl"
#   },
#   "settings":{
#     "invoiceDisabled":"true"
#   },
#   "products": [
#     {
#       "name": "Wireless Mouse for Laptop",
#       "unitPrice": "15000",
#       "quantity": "1"
#     },
#     {
#       "name": "HDMI cable",
#       "unitPrice": "6000",
#       "quantity": "1"
#     }
#   ]
# }'
# pp body
# pp Time.now
# res = Net::HTTP.post(
#   URI(api_url),
#   body,
#   {
#     "Content-Type" => "application/json",
#     "Authorization" => "Bearer #{token}"
#   }
# )

# pp "res2:"
# pp res
# pp res.body





################################################################
body = {}
body[:notifyUrl] = "https://activemerchant-payu-integration.com/notify"
body[:customerIp] = '127.0.0.1'
body[:merchantPosId] = '300746'
body[:description] = "RTV market"
body[:currencyCode] = 'PLN'
body[:totalAmount] = '21000'
body[:buyer] = {}
body[:buyer][:email] = "john.doe@example.com",
body[:buyer][:phone] = "654111654"
body[:buyer][:firstName] = "John"
body[:buyer][:lastName] = "Doe"
body[:buyer][:language] = "pl"
body[:settings] = {}
body[:settings][:invoiceDisabled] = true
body[:products] = []
body[:products][0] = {}
body[:products][0][:name] = "Wireless mouse for laptop"
body[:products][0][:unitPrice] = "15000"
body[:products][0][:quantity] = "1"

def post_data(body)
  str = ''
  body.each do |key, value|
    str << "\"#{key}: #{value}\""
  end
  body
end
# body = body.to_json
# # pp body.to_query
# # purchase


# puts "\n\nbody as serialized json"
# pp body
# sleep 1
# pp Time.now
# res = Net::HTTP.post(
#   URI(api_url),
#   body.to_json,
#   {
#     "Content-Type" => "application/json",
#     "Authorization" => "Bearer #{token}"
#   }
# )

# pp "res1:"
# pp res # => #<Net::HTTPBadRequest 400 Bad Request readbody=true>
# pp res.body # => "{\"status\":{\"statusCode\":\"ERROR_SYNTAX\",\"code\":\"103\",\"codeLiteral\":\"ERROR_SYNTAX\",\"statusDesc\":\"Bad syntax\"}}"







########################################################################
# puts "\n\nbody as normal string with single quotes"
# body = "{
#   'notifyUrl': 'https://activemerchant-payu-integration.com/notify',
#   'customerIp': '127.0.0.1',
#   'merchantPosId': '300746',
#   'description': 'RTV market',
#   'currencyCode': 'PLN',
#   'totalAmount': '21000',
#   'buyer': {
#     'email': 'john.doe@example.com',
#     'phone': '654111654',
#     'firstName': 'John',
#     'lastName': 'Doe',
#     'language': 'pl'
#   },
#   'settings':{
#     'invoiceDisabled':'true'
#   },
#   'products': [
#     {
#       'name': 'Wireless Mouse for Laptop',
#       'unitPrice': '15000',
#       'quantity': '1'
#     },
#     {
#       'name': 'HDMI cable',
#       'unitPrice': '6000',
#       'quantity': '1'
#     }
#   ]
# }"
# sleep 1
# pp Time.now
# res = Net::HTTP.post(
#   URI(api_url),
#   body,
#   {
#     "Content-Type" => "application/json",
#     "Authorization" => "Bearer #{token}"
#   }
# )

# pp "res3:"
# pp res # => #<Net::HTTPBadRequest 400 Bad Request readbody=true>
# pp res.body # => "{\"status\":{\"statusCode\":\"ERROR_SYNTAX\",\"code\":\"103\",\"codeLiteral\":\"ERROR_SYNTAX\",\"statusDesc\":\"Bad syntax\"}}"

# ... body z pojedynczym cudzysłowem zwraca 400, z podwojnym 302











# Dzień dobry, dzięki za odpowiedź. Faktycznie problem byl w body zapytania.

# 1. endpoint 'api/v2_1/orders' zwraca dobrą odpowiedź 302 dla body typu string podzielonego nowymi liniami (request z 2020-04-06 18:04:48 +0200):
# ```
# '{
#     "notifyUrl": "https://your.eshop.com/notify",
#     "customerIp": "127.0.0.1",
#     "merchantPosId": "300746",
#     "description": "RTV market",
#     "currencyCode": "PLN",
#     "totalAmount": "21000",
#     "buyer": {
#       "email": "john.doe@example.com",
#       "phone": "654111654",
#       "firstName": "John",
#       "lastName": "Doe",
#       "language": "pl"
#     },
#     "settings":{
#       "invoiceDisabled":"true"
#     },
#     "products": [
#       {
#         "name": "Wireless Mouse for Laptop",
#         "unitPrice": "15000",
#         "quantity": "1"
#       },
#       {
#         "name": "HDMI cable",
#         "unitPrice": "6000",
#         "quantity": "1"
#       }
#     ]
#   }'
# ```

# i zwraca 400 dla zserializowanego JSONa z taką samą zawartością jak powyżej (request z 2020-04-06 18:04:49 +0200):
# ```
# "{\"notifyUrl\":\"https://activemerchant-payu-integration.com/notify\",\"customerIp\":\"127.0.0.1\",\"merchantPosId\":\"300746\",\"description\":\"RTV market\",\"currencyCode\":\"PLN\",\"totalAmount\":\"21000\",\"buyer\":{\"phone\":\"654111654\",\"email\":[\"john.doe@example.com\",\"654111654\"],\"firstName\":\"John\",\"lastName\":\"Doe\",\"language\":\"pl\"},\"settings\":{\"invoiceDisabled\":true},\"products\":[{\"name\":\"Wireless mouse for laptop\",\"unitPrice\":\"15000\",\"quantity\":\"1\"}]}"
# ```

# Chciałbym móc wysłać body jako zserializowany JSON. Czy ten endpoint zwraca 302 tylko dla stringa podzielonego nowymi linami?


# Środowisko: publiczny sandbox
# pos id: 300746
# czasy są podane w namiasach w przykładch requestów powyżej
# unikalna wartość: activemerchant-payu-integration.com/notify
