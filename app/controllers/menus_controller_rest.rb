class MenusController < ApplicationController
  require 'ordrin'
  require 'rest-client'

  API_ROOT_DIR = 'https://r-test.ordr.in'    # Change me, in production.
  API_DATETIME = '06-22+16:00'
  API_ZIP = '07094'
  API_CITY = 'Secaucus'
  API_ADDR = '400 Park Pl'
  API_KEY = ENV["ORDRIN_SECRET"]
  API_AUTH = 'id="' + API_KEY + '", version="1"'


  before_action :setup_api, only: [ :create ]

  def create

    zip = "10036"
    addr = '1540 Broadway'
    city = zip.to_region(:city => true)
    state = zip.to_region(:state => true)

    address = {
      datetime: 'ASAP',
      addr:     addr,
      city:     city,
      zip:      zip
    }

    cuisines = ['American', 'Indian', 'Thai','Italian']

    budget_low = params[:budget_low].to_i
    budget_high = params[:budget_high].to_i
    servings = params[:servings].to_i

    @restaurant = find_restaurant(address, cuisines, budget_low)

    @order = build_order(@restaurant["menu"], budget_low, budget_high, servings)

    @tray = build_tray(@order)

    order_args = {
      "rid" =>        '147',
      "em" =>         "test@test.com",
      "tray" =>       '4622440/1,4622442+4622452/1+4622476/1',
      "tip" =>        '5.05',

      "first_name" => "Joshua",
      "last_name" =>  "Tester",
      "phone" =>      '6478967502',
      "zip" =>        zip,
      "addr" =>       addr,
      "city" =>       city,
      "state" =>      state,

      "card_name" =>        "Joshua Tester",
      "card_number" =>      '4111111111111111',
      "card_cvc" =>         '123',
      "card_expiry" =>      '02/2016',
      "card_bill_addr" =>   addr,
      "card_bill_city" =>   city,
      "card_bill_state" =>  state,
      "card_bill_zip" =>    zip,
      "card_bill_phone" =>  '6478967502',

      "delivery_date" =>    "ASAP",
      # delivery_time:    "ASAP"

    }


    @response = @api.order_guest(order_args.to_json)

    # api_request = URI.encode("#{API_ROOT_DIR}/dl/#{API_DATETIME}/#{API_ZIP}/#{API_CITY}/#{API_ADDR}")
    # response = RestClient.post(
    #   api_request,
    #   { 'X-NAAMA-CLIENT-AUTHENTICATION' => API_AUTH }
    #  )

    # RestClient.post( url,
    # {
    #   :transfer => {
    #     :path => '/foo/bar',
    #     :owner => 'that_guy',
    #     :group => 'those_guys'
    #   },
    #    :upload => {
    #     :file => File.new(path, 'rb')
    #   }
    # })

    # @restaurants = JSON.parse(response)


    render :json => @response

    # render :json => order_args

  end

  def build_order(restaurant, budget_low, budget_high, servings)
    possibilities = recursive_menu_gen(restaurant, [], budget_low, budget_high)
    possibilities.sample(servings)
  end

  def build_tray(orders)
    tray = []
    orders.each do |o|
      tray << "#{o[:id]}/1"
    end
    tray.join(",+")
  end

  def recursive_menu_gen(r_object, keepers, budget_low, budget_high)
    # Make sure we don't keep max_child_select.
    
    r_object.each do |r_key, r_value|
      r_value = r_key if r_object.is_a? Array
      if r_value.class == Hash || r_value.class == Array
        recursive_menu_gen(r_value, keepers, budget_low, budget_high)
      elsif r_key == 'price' && r_value.to_f >= budget_low && r_value.to_f <= budget_high
        new_obj = {
          id: r_object["id"],
          price: r_object["price"],
          name: r_object["name"],
          descrip: r_object["descrip"]
        }
        keepers << new_obj
      end
    end
    keepers
  end


# The tray is composed of menu items and optional sub-items. A single menu item's format is: 
# [menu item id]/[qty],[option id],[option id]... Multiple menu items are joined by a +: 
# [menu item id]/[qty]+[menu item id2]/[qty2] For example: 3270/2+3263/1,3279 Means 2 of menu item 3270 
# (with no sub options) and 1 of item num 3263 with sub option 3279.

  def find_restaurant(address, cuisines, budget_low)
    # Get a list of all restaurants that deliver to this address from the API
    @all_restaurants = @api.delivery_list(address)

    # Filter down to the valid restaurants for this purpose
    @valid_restaurants = get_valid_restaurants(@all_restaurants, cuisines, budget_low)

    # Grab a random validated restaurant!
    @chosen_restaurant = @valid_restaurants.sample

    # Get restaurant info from API
    r_object = {
      rid: @chosen_restaurant['id'].to_s
    }
    
    # Return restaurant
    @api.restaurant_details(r_object)
  end


  private
  
  def get_valid_restaurants(rest, cuisines, budget_low)
    rest.select do |r|
      ( 
        ( r["services"]["deliver"]["can"] == 1 ) &&
        ( r["services"]["deliver"]["time"] < 60 ) && 
        ( r["services"]["deliver"]["mino"] <= budget_low ) && 
        ( cuisines.any? { |cuisine| r["cu"].include? cuisine } if r["cu"] ) 
      )
    end
  end

  def setup_api
    @api = Ordrin::APIs.new(ENV['ORDRIN_SECRET'], :test)
  end


end
