_                = require 'lodash'
PassportStrategy = require 'passport-strategy'
request          = require 'request'
url              = require 'url'
MeshbluHttp      = require 'meshblu-http'
MeshbluConfig    = require 'meshblu-config'

class MeshbluStrategy extends PassportStrategy
  constructor: (env) ->
    if _.isEmpty env.ENDO_MESHBLU_MESHBLU_CALLBACK_URL
      throw new Error('Missing required environment variable: ENDO_MESHBLU_MESHBLU_CALLBACK_URL')
    if _.isEmpty env.ENDO_MESHBLU_MESHBLU_AUTH_URL
      throw new Error('Missing required environment variable: ENDO_MESHBLU_MESHBLU_AUTH_URL')
    if _.isEmpty env.ENDO_MESHBLU_MESHBLU_SCHEMA_URL
      throw new Error('Missing required environment variable: ENDO_MESHBLU_MESHBLU_SCHEMA_URL')
    if _.isEmpty env.ENDO_MESHBLU_MESHBLU_FORM_SCHEMA_URL
      throw new Error('Missing required environment variable: ENDO_MESHBLU_MESHBLU_FORM_SCHEMA_URL')

    @_authorizationUrl = env.ENDO_MESHBLU_MESHBLU_AUTH_URL
    @_callbackUrl      = env.ENDO_MESHBLU_MESHBLU_CALLBACK_URL
    @_schemaUrl        = env.ENDO_MESHBLU_MESHBLU_SCHEMA_URL
    @_formSchemaUrl    = env.ENDO_MESHBLU_MESHBLU_FORM_SCHEMA_URL
    super

  authenticate: (req) -> # keep this skinny
    {bearerToken} = req.meshbluAuth
    {uuid, token} = req.body
    return @redirect @authorizationUrl({bearerToken}) unless token?
    @getUserRecordFromMeshblu {uuid, token}, (error, user) =>
      return @fail 401 if error? && error.code < 500
      return @error error if error?
      @success {
        id:       user.uuid
        username: user.name ? user.uuid
        secrets:
          credentials:
            uuid: user.uuid
            token: user.token
      }

  authorizationUrl: ({bearerToken}) ->
    {protocol, hostname, port, pathname} = url.parse @_authorizationUrl
    query = {
      postUrl: @postUrl()
      schemaUrl: @schemaUrl()
      formSchemaUrl: @formSchemaUrl()
      bearerToken: bearerToken
    }
    return url.format {protocol, hostname, port, pathname, query}

  formSchemaUrl: ->
    @_formSchemaUrl

  getUserRecordFromMeshblu: ({uuid, token}, callback) =>
    meshbluConfig = new MeshbluConfig
    config = _.defaults {uuid, token}, meshbluConfig.toJSON()
    meshbluHttp = new MeshbluHttp config
    meshbluHttp.whoami (error, device) =>
      return callback error if error?
      data =
        uuid: uuid
        token: token
        name: device.name ? device.uuid
      callback null, data

  postUrl: ->
    {protocol, hostname, port} = url.parse @_callbackUrl
    return url.format {protocol, hostname, port, pathname: '/auth/api/callback'}

  schemaUrl: ->
    @_schemaUrl

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = MeshbluStrategy
