MeshbluHttp = require 'meshblu-http'
http = require 'http'

class GetDevice
  constructor: ({@encrypted}) ->
    @auth = @encrypted.secrets.credentials
    @meshbluHttp = new MeshbluHttp @auth

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.uuid is required') unless data.uuid?
    { uuid } = data

    @meshbluHttp.device uuid, (error, result) =>
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

module.exports = GetDevice
