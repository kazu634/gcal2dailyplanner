require 'rubygems'
require 'bundler'

require 'sinatra'

require 'omniauth'
require 'omniauth-google-oauth2'

require 'google/api_client'

require "sinatra/activerecord"

require 'will_paginate'
require 'will_paginate/view_helpers/sinatra'
require 'will_paginate/active_record'

require_relative 'models/init'

Time.zone = "Tokyo"
ActiveRecord::Base.default_timezone = :local

ENV['RACK_ENV'] ||= 'development'


class GCalSorter < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  helpers  WillPaginate::Sinatra::Helpers

  get '/' do
    if logged_in?
      redirect '/mypage'
    else
      @javascript = 'index.js'
      erb :index
    end
  end

  get '/mypage' do
    if logged_in?
      @user = User.find_by_uid(session['uid'])
      @javascript = 'mypage.js'

      erb :mypage
    else
      redirect '/'
    end
  end

  get '/logoff' do
    session.clear

    redirect '/'
  end

  get '/auth/:provider/callback' do
    # Find the user information.
    # If the user information isn't found, insert the user information to the database.
    # Otherwise, just updte the user information.

    user = User.find_or_initialize_by(uid: env['omniauth.auth']['uid'])

    user.uid = env['omniauth.auth']['uid']
    user.name = env['omniauth.auth']['info']['name']
    user.token = env['omniauth.auth']['credentials']['token']
    user.refresh_token = env['omniauth.auth']['credentials']['refresh_token']
    user.expires_at = env['omniauth.auth']['credentials']['expires_at']

    user.save

    # Store UID to the session data
    session[:uid] = env['omniauth.auth']['uid']

    redirect '/'
  end

  get '/auth/failure' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end

  post '/events' do
    from = Time.now.getlocal.at_beginning_of_day
    to   = from + 180.day

    @events = User.find_by_uid(session[:uid]).events.where(end: from...to).order(event_updated: :desc).page(params[:page])

    if @events.count == 0
      "<div id='events' class='alert alert-danger'><p>Googleからカレンダー情報を取得していません。<a href='#' id='retrieve' class='alert-link'>ここ</a>をクリックして、カレンダー情報を取得してください。</p></div>"
    else
      erb :events, :layout => false
    end
  end

  post '/update' do
    retrieve_calendars
    retrieve_events

    "<div id='events' class='alert alert-success'><p>Googleからカレンダー情報を取得しました。<a href='/mypage' class='alert-link'>ここ</a>をクリックして、ページを更新してください。</p></div>"
  end

  post '/description' do
    erb :description, :layout => false
  end

  enable :sessions, :logging

  use Rack::Session::Cookie,
  #  :key => 'rack.session',
  #  :domain => 'localhost',
  #  :path => '/',
    :expire_after => 60*60*24*14, # 2 weeks
    :secret => 'secret'

  use OmniAuth::Builder do
    provider :google_oauth2,
      '902428778390-b8s9o929eckcq9j80kihlt290ee9rb6r.apps.googleusercontent.com',
      'Xrs6zkRiliv8SGv8wWdd4rXW',
      {
        :scope => "calendar userinfo.email",
        :prompt => "consent"
      }
  end

  helpers do
    # define a logged_in? method, so we can be sure if an user is authenticated
    def logged_in?
      !session[:uid].nil?
    end

    def token_expires?
      User.find_by_uid(session[:uid]).expires_at < Time.now.to_i
    end

    def unix2jst(unix)
      Time.at(unix)
    end

    def retrieve_calendars
      user = User.find_by_uid(session[:uid])

      client = Google::APIClient.new(
        :application_name => 'Google Calendar Sorter',
        :application_version => '0.0.1'
      )

      client.authorization.client_id     = '902428778390-b8s9o929eckcq9j80kihlt290ee9rb6r.apps.googleusercontent.com'
      client.authorization.client_secret = 'Xrs6zkRiliv8SGv8wWdd4rXW'
      client.authorization.scope         = "https://www.googleapis.com/auth/calendar"
      client.authorization.refresh_token = user.refresh_token

      if token_expires?
        client.authorization.fetch_access_token!

        user.token = client.authorization.access_token
        user.expires_at = Time.now.to_i + 3590

        user.save
      else
        client.authorization.access_token = user.token
      end

      cal = client.discovered_api('calendar', 'v3')

      page_token = nil
      result = client.execute(:api_method => cal.calendar_list.list)

      retrieve_data = []
      loop do
        result.data.items.each do |item|
          retrieve_data << item
        end

        if !(page_token = result.data.next_page_token)
          break
        else
          result = @client.execute(:api_method => cal.calendar_list.list,
                                   :parameters => {'pageToken' => _page_token})
        end
      end

      # variable for storing the retrieved calendar ids
      retrieved_calendar_ids = []

      retrieve_data.each do |cal|
        calendar = Calendar.find_or_initialize_by(calid: cal.id)

        calendar.calid      = cal.id
        calendar.calendar   = cal.summary
        calendar.etag       = cal.etag
        calendar.timezone   = cal.timeZone
        calendar.bgcolor    = cal.backgroundColor
        calendar.fgcolor    = cal.foregroundColor
        calendar.accessrole = cal.accessRole
        calendar.user_id    = user.id

        calendar.save

        retrieved_calendar_ids << cal.id
      end

      # Calculate the collection of the deleted calendar ids
      # by subtracting the retrieved calendar ids
      # from the calendar ids in the database.
      deleted_calendar_ids = user.calendars.pluck(:calid) - retrieved_calendar_ids

      deleted_calendar_ids.each do |deleted_calendar_id|
        user.calendars.where("calid = ?", deleted_calendar_id).destroy_all
      end

    end

    def retrieve_events
      user = User.find_by_uid(session[:uid])
      calendars = user.calendars.where("accessrole = ?", "owner")

      client = Google::APIClient.new(
        :application_name => 'Google Calendar Sorter',
        :application_version => '0.0.1'
      )

      client.authorization.client_id = '902428778390-b8s9o929eckcq9j80kihlt290ee9rb6r.apps.googleusercontent.com'
      client.authorization.client_secret = 'Xrs6zkRiliv8SGv8wWdd4rXW'
      client.authorization.scope = "https://www.googleapis.com/auth/calendar"
      client.authorization.refresh_token = user.refresh_token

      if token_expires?
        client.authorization.fetch_access_token!

        user.token = client.authorization.access_token
        user.expires_at = Time.now.to_i + 3590

        user.save
      else
        client.authorization.access_token = user.token
      end

      service = client.discovered_api('calendar', 'v3')

      events = []
      # storing the event ids retrieved from Google Calendar
      retrieved_event_ids = []

      calendars.each do |calendar|
        from, to = calc_range

        params = {"calendarId" => calendar.calid,
                  "timeMax" => to,
                  "timeMin" => from}

        page_token = nil
        result = client.execute(:api_method => service.events.list,
                                :parameters => params)

        tmp = []
        loop do
          result.data.items.each do |item|
            tmp << item
          end

          if !(page_token = result.data.next_page_token)
            break
          else
            params["pageToken"] = page_token
            result = client.execute(:api_method => service.events.list,
                                    :parameters => params)
          end
        end

        tmp.each do |t|
          event = Event.find_or_initialize_by(event_id: t.id)

          event.event_id      = t.id
          event.event         = t.summary
          event.start         = start_datetime_of(t)
          event.end           = end_datetime_of(t)
          event.status        = t.status
          event.etag          = t.etag
          event.link          = t.htmlLink
          event.event_created = t.created
          event.event_updated = t.updated
          event.user_id       = user.id
          event.calendar_id   = calendar.id

          event.save

          retrieved_event_ids << t.id
        end
      end

      # Calculate the collection of the deleted event ids
      # by subtracting the retrieved event ids
      # from the event ids in the database.

      from = 90.days.ago.at_beginning_of_day
      to   = Time.now.at_beginning_of_day + 180.day

      deleted_event_ids = user.events.where(start: from...to).pluck(:event_id) - retrieved_event_ids

      deleted_event_ids.each do |event_id|
        event = Event.find_by_event_id(event_id)

        if event.status != "cancelled"
          event.status = "cancelled"

          event.event_updated = Time.now.strftime("%Y/%m/%d %H:%M:%S.#{Time.now.utc.usec.to_s[0, 3]}")

        end

        event.save
      end
    end
  end

  def calc_range
    from = Date.today - 90
    to   = Date.today + 180

    result = []

    result << Time.utc(from.year , from.month , from.day , 0).iso8601
    result << Time.utc(to.year   , to.month   , to.day   , 0).iso8601

    return result
  end

  def start_datetime_of(datetime_obj)
    if datetime_obj.start.date
      Time.parse(datetime_obj.start.date.to_s).getlocal.strftime("%Y-%m-%d %H:%M:%S")
    elsif datetime_obj.start.dateTime
      Time.parse(datetime_obj.start.dateTime.to_s).getlocal.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  def end_datetime_of(datetime_obj)
    if datetime_obj.end.date
      Time.parse(datetime_obj.end.date.to_s).getlocal.strftime("%Y-%m-%d %H:%M:%S")
    elsif datetime_obj.end.dateTime
      Time.parse(datetime_obj.end.dateTime.to_s).getlocal.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  def date_for(datetime)
    return Time.parse(datetime).getlocal.strftime("%Y-%m-%d")
  end

  def time_for(datetime)
    result = Time.parse(datetime).getlocal.strftime("%H:%M:%S")

    if result == "00:00:00"
      result = "-"
    end

    return result
  end

  def datetime_for(datetime)
    return Time.parse(datetime).getlocal.strftime("%Y-%m-%d %H:%M:%S")
  end
end
