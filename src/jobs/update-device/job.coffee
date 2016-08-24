MeshbluHttp = require 'meshblu-http'
http   = require 'http'
_      = require 'lodash'

class UpdateDevice
  constructor: ({@encrypted}) ->
    @auth = @encrypted.secrets.credentials
    @meshbluHttp = new MeshbluHttp @auth

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.uuid is required') unless data.uuid?
    return callback @_userError(422, 'data.updateJSON is required') unless data.updateJSON?
    options = {}
    { uuid, updateJSON } = data
    update = updateJSON
    update = JSON.parse(updateJSON) if _.isString updateJSON

    @meshbluHttp.updateDangerously uuid, update, (error, result) =>
      return callback error if error?
      return callback null, {
        metadata:
          code: 204
          status: http.STATUS_CODES[204]
        data: result
      }

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = UpdateDevice
