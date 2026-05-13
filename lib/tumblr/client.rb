# typed: true
require 'faraday'
require 'simple_oauth'
require 'json'
require 'uri'

module Tumblr
  class Client
    API_HOST = 'api.tumblr.com'
    API_BASE = "https://#{API_HOST}"

    def initialize(attrs = {})
      @consumer_key = attrs[:consumer_key]
      @oauth_attrs = {
        consumer_key: attrs[:consumer_key],
        consumer_secret: attrs[:consumer_secret],
        token: attrs[:oauth_token],
        token_secret: attrs[:oauth_token_secret],
      }
    end

    def posts(blog_name, options = {})
      params = { api_key: @consumer_key }.merge(options)
      get("v2/blog/#{full_blog_name(blog_name)}/posts", params)
    end

    def likes(options = {})
      get('v2/user/likes', options)
    end

    def edit(blog_name, options = {})
      post("v2/blog/#{full_blog_name(blog_name)}/post/edit", options)
    end

    def unlike(id, reblog_key)
      post('v2/user/unlike', { id: id, reblog_key: reblog_key })
    end

    private

    def full_blog_name(blog_name)
      blog_name.include?('.') ? blog_name : "#{blog_name}.tumblr.com"
    end

    def connection
      @connection ||= Faraday.new(url: API_BASE) do |conn|
        conn.adapter :net_http
      end
    end

    def get(path, params = {})
      url = "#{API_BASE}/#{path}"
      str_params = stringify_and_compact(params)
      response = connection.get("/#{path}") do |req|
        req.params = str_params
        req.headers['Authorization'] = oauth_header('GET', url, str_params)
      end
      handle_response(response)
    end

    def post(path, params = {})
      url = "#{API_BASE}/#{path}"
      str_params = stringify_and_compact(params)
      response = connection.post("/#{path}") do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.headers['Authorization'] = oauth_header('POST', url, str_params)
        req.body = URI.encode_www_form(str_params)
      end
      handle_response(response)
    end

    def oauth_header(method, url, params = {})
      SimpleOAuth::Header.new(method, url, params, @oauth_attrs).to_s
    end

    def handle_response(response)
      body = JSON.parse(response.body)
      if [200, 201].include?(response.status)
        body['response']
      else
        res = body['meta'] || {}
        res.merge!(body['response']) if body['response'].is_a?(Hash)
        res
      end
    end

    def stringify_and_compact(hash)
      hash.compact.transform_keys(&:to_s)
    end
  end
end
