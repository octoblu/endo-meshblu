MeshbluHttp   = require 'meshblu-http'
MeshbluConfig = require 'meshblu-config'
http          = require 'http'
_             = require 'lodash'

class SearchDevices
  constructor: ({@encrypted}) ->
    @auth = @encrypted.secrets.credentials
    throw new Error 'Job requires auth.uuid' if _.isEmpty @auth?.uuid
    throw new Error 'Job requires auth.token' if _.isEmpty @auth?.token
    meshbluConfig = new MeshbluConfig
    config = _.defaults @auth, meshbluConfig.toJSON()
    @meshbluHttp = new MeshbluHttp config

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.query is required') unless data.query?
    { query, projection, as } = data
    query = JSON.parse(query) if _.isString query
    projection = JSON.parse(projection) if _.isString projection

    metadata = {}
    metadata.projection = projection unless _.isEmpty projection
    metadata.as = as unless _.isEmpty as

    @meshbluHttp.search query, metadata, (error, result) =>
      return callback error if error?
      return callback null, {
        metadata:
          code: 200
          status: http.STATUS_CODES[200]
          performedBy: as ? @auth.uuid
          query: query
        data: result
      }

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = SearchDevices
