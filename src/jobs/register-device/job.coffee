MeshbluHttp   = require 'meshblu-http'
MeshbluConfig = require 'meshblu-config'
http          = require 'http'
_             = require 'lodash'

class RegisterDevice
  constructor: ({@encrypted}) ->
    @auth = @encrypted.secrets.credentials
    throw new Error 'Job requires auth.uuid' if _.isEmpty @auth?.uuid
    throw new Error 'Job requires auth.token' if _.isEmpty @auth?.token
    meshbluConfig = new MeshbluConfig
    config = _.defaults @auth, meshbluConfig.toJSON()
    @meshbluHttp = new MeshbluHttp config

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.options is required') unless data.options?
    { options } = data

    options = JSON.parse options if _.isString options

    @meshbluHttp.register options, (error, result) =>
      return callback error if error?
      return callback null, {
        metadata:
          code: 200
          status: http.STATUS_CODES[200]
        data: result
      }

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = RegisterDevice
