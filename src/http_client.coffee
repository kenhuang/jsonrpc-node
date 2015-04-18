BasicAuth = require "./http_client_basic_auth"
{EventEmitter} = require "events"

class Client extends EventEmitter
  constructor:(@port, @host, secure)->
    @transport = require if secure? and secure then "https" else "http"

  setAuth:(@auth)->

  setBasicAuth: (username, password)->
    @setAuth new BasicAuth username, password

  sendData:(request, headers, callback )->
    if !callback?
      callback = headers
      headers = {}

    options =
      host: @host
      port: @port
      method: "post"
      path: @path||"/"
      headers: headers

    options.headers.Host = @host

    if @auth?
      @auth.sign options, request

    query = JSON.stringify request
    options.headers['Content-Length'] = query.length
    options.headers["Content-Type"]  = "application/json"

    options.rejectUnauthorized = false

    request = @transport.request options

    request.on "error", (err)->
      callback err

    request.on "response", (response)->
      buffer = ''
      response.on 'data', (chunk)->
        buffer += chunk
      response.on 'end', ()->
        err = null
        msg = null
        if response.statusCode == 200
          try
            json = JSON.parse buffer
            if json.error? then err = new Error json.error
            if json.result then msg = json.result
          catch e
            err = e
        else
          err = "Server replied with : "+response.statusCode
        callback err, msg
    request.end query

  call: (method, params, callback)->
    request = {method: method, params: params, id:Date.now()}
    @sendData request, callback

  sendNotification: (method, params, callback)->
    @sendData id:null, method:method, params:params, callback

  onceReady:(callback)-> callback()

module.exports = Client