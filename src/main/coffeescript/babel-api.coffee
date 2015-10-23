class BabelApi
  constructor: (url, options={}) ->

    if url 
      if url.url
        options = url
      else
        @url = url
    else
      options = url
    @url = options.url if options.url?
    
    parts = @url.split("/")
    @baseUrl = parts[0] + "//" + parts[2]

    @success = options.success if options.success?
    @build() if options.success?

  build: () ->  
    obj = 
      url: @url
      method: "get"
      headers: {}
      on:
        error: (error) =>          
          if @url.substring(0, 4) isnt 'http'
            @fail 'Please specify the protocol for ' + @url
          else if error.status == 0
            @fail 'Can\'t read from server.  It may not have the appropriate access-control-origin settings.'
          else if error.status == 404
            @fail 'Can\'t read babel JSON from '  + @url
          else
            @fail error.status + ' : ' + error.statusText + ' ' + @url
        response: (rawResponse) =>
          response = JSON.parse(rawResponse.content.data)       
          
          @headers = []
          for header in response.headers
            @headers.push {name:header.name, val:header.value}  
          @serviceUrl = response.serviceUrl     
          @serviceMap = {}
          @serviceArray = []
          for srv in response.services
            @serviceMap[srv.name] = srv                       
            @serviceArray.push srv
          if this.success
            this.success()          
          this
          
    new BabelHttp().execute obj
    @   
    
  fail: (message) ->
    throw message   
    
  loadService: (serviceName, success) ->

    srv = @serviceMap[serviceName]
    url = @baseUrl + srv.path
    obj = 
      url: url
      method: "get"
      headers: {}
      on:
        error: (response) =>
          alert "temp failed"
        response: (rawResponse) =>
          response = JSON.parse(rawResponse.content.data)
          service = new BabelService response.name, response.comment, response.methods, response.structs, response.enums, this
          if success
            success(service)  
    new BabelHttp().execute obj
      
class BabelService
  
  constructor: (@name, @comment, methods, structs, enums, @api) ->
    @addEnums(enums)
    @addStructs(structs)    
    @addMethods(methods)
    
  addStructs: (structs) ->

    @structMap = {}
    if structs
      for name, obj of structs
        @structMap[name] = new Struct name, obj, @ 
        
  addEnums: (enums) ->
    
    @enumMap = {}
    if enums
      for name, obj of enums
        @enumMap[name] = new Enum name, obj
    
  addMethods: (methods) ->
    
    @methodArray = []
    @methodMap = {}
    if methods
      for meth in methods
        srv = new ServiceMethod meth, @, @api
        @methodMap[meth.name] = srv
        @methodArray.push srv
        
class ServiceMethod
  name:null
  comment:null
  params:[]
  returns:null
  
  constructor: (meth, @service, @api) ->
    @name = meth.name
    @comment = meth.comment
    if meth.returns?
      @returns = new PropObject "", meth.returns, @service
    @params = []
    for name, prop of meth.params
      @addParam name, prop
    @buildJSON()
    @signature = @buildSignature()
    @returnType = if @returns? then @returns.typeToString() else "void"
    
  addParam: (name, prop) ->
    
    methodParam = new PropObject name, prop, @service
    @params.push methodParam
    
  buildJSON: () ->
    signature = {}
    for prop in @params
      signature[prop.name] = prop.buildJSON()
    @sampleJSON = JSON.stringify(signature , null, 2)
    
  buildSignature: () ->
    sign = ""
    if @returns
      sign += @returns.toString()
    else
      sign += "void"
    sign += " " + @name + "("
    for p, i in @params
      sign += p.toString()
      if @params.length != (i + 1)
        sign += ", "      
    sign += ")"
    sign
    
  getEnums: () ->
    
    walkStructProperties = (struct, enumMap, allEnums, allStructs, structMap) ->
      
      structMap = structMap || {}
      return if structMap[struct.name]
      structMap[struct.name] = struct
      for prop in struct.propsArray
        if prop.enumRef?
          enumObj = allEnums[prop.enumRef]
          enumMap[enumObj.name] = enumObj
        else if prop.ref?
          walkStructProperties allStructs[prop.ref], enumMap, allEnums, allStructs, structMap
        else if prop.listPropObj?   
          addCollectionEnums prop, enumMap, allEnums          

    addCollectionEnums = (prop, enumMap, allEnums) ->
      listObj = prop.listPropObj
      while listObj?
        if listObj.enumRef? then enumMap[listObj.enumRef] = allEnums[listObj.enumRef]
        listObj = listObj.listPropObj      
    
    propObjects = [].concat(@params)
    if @returns? then propObjects.push(@returns)
    enums = []
    enumMap = {}
    
    for key, prop of propObjects
      if prop.enumRef?
        enumObj = @service.enumMap[prop.enumRef]
        enumMap[enumObj.name] = enumObj
      else if prop.ref?
        walkStructProperties @service.structMap[prop.ref], enumMap, @service.enumMap, @service.structMap
      else if prop.listPropObj?
        addCollectionEnums prop, enumMap, @service.enumMap
    
    for key, prop of enumMap
      enums.push prop  
    enums.sort (a, b) -> if a.name >= b.name then 1 else -1
    
  getStructs: () ->
    
    addCollectionStructs = (prop, structMap, allStructs) ->
      listObj = prop.listPropObj
      while listObj?
        if listObj.ref? then addStruct(allStructs[listObj.ref], structMap, allStructs)
        listObj = listObj.listPropObj      
    
    addStruct = (struct, structMap, allStructs) ->
      return if structMap[struct.name] # do not add struct if it was already added, in case of circular references
      structMap[struct.name] = struct
      for prop in struct.propsArray
        if prop.ref?
          addStruct allStructs[prop.ref], structMap, allStructs
        else if prop.listPropObj?   
          addCollectionStructs prop, structMap, allStructs          
      
      if struct.parent? 
        structMap[struct.parent] = allStructs[struct.parent] 
        addStruct(allStructs[struct.parent], structMap, allStructs)
    
    propObjects = [].concat(@params)
    if @returns? then propObjects.push(@returns)
    structs = []
    structMap = {}
    for key, prop of propObjects
      if prop.ref?
        struct = @service.structMap[prop.ref]
        addStruct struct, structMap, @service.structMap
      else if prop.listPropObj?   
        addCollectionStructs prop, structMap, @service.structMap 
      
    for key, prop of structMap
      structs.push prop  
    structs.sort (a, b) -> if a.name >= b.name then 1 else -1
    
  perform: (url, headers, content, callback) ->

    reqHeaders = {
        "Content-Type":"application/json"
        "Accept":"application/json"      
    }
    if headers?
      for prop in headers
        reqHeaders[prop.name] = prop.val 

    meth = @

    obj = 
      url: @buildUrl(window.location.href.toString(), url)
      method: "post"
      headers: reqHeaders
      body: content
      on:
        error: (rawResponse) =>
          result
          if rawResponse.content.data
            response = JSON.parse(rawResponse.content.data)
          else
            result = "No Error Response Retrieved"
          if callback
            callback(response , false)            
        response: (rawResponse) =>
          result
          if rawResponse.content.data
            response = JSON.parse(rawResponse.content.data)
            result = JSON.stringify(response, null, 2)
          else if meth.returns?
            result = "Success!!, method returned NULL"
          else
            result = "Success!!, Method returns VOID"          
          if callback
            callback(result, true)
          
    new BabelHttp().execute obj
    
  buildUrl: (base, url) ->
    parts = base.split("/")
    base = parts[0] + "//" + parts[2]
    if url.indexOf("/") is 0
      base + url
    else
      base + "/" + url       
    
class Struct
  name:null
  comment:null
  parent:null
  propObjectMap:{}
  propsArray:[]
  constructor: (name, obj, @service) ->
    @name = name
    @comment = obj.comment
    if obj.parent? then @parent = obj.parent
    @propObjectMap = {}
    @propsArray = []
    for name, prop of obj.properties
      propObject = new PropObject name, prop, @service
      @propsArray.push propObject
      @propObjectMap[name] = propObject  
      
class Enum
  name:null
  values:[]
  constructor: (name, obj) ->
    @name = name
    @values = []
    for key, val of obj.values
      @values.push({name:key, val:val})
    
class PropObject
  name:null
  type:null
  keyType:null
  ref:null
  enumRef:null
  comment:null
    
  constructor: (name, prop, @service) ->
      @name = name
      @type = prop.type
      @keyType = prop.keyType
      @ref = prop.ref
      @enumRef = prop.enumRef
      @comment = prop.comment
      
      if prop.items
        @listPropObj = new PropObject "", prop.items, @service
    
  buildJSON: (callStack) ->
        
    addTo = (callStack, prop) ->
      return unless prop.ref?
      unless callStack[prop.ref]
        callStack[prop.ref] = 0
      callStack[prop.ref]++      
      
    exceededCallStack = (callStack, prop) ->      
      callStack[prop.ref]? && callStack[prop.ref] >= 2
    
    addStruct = (callStack, struct, val, atRoot, map) -> 
      for prop in struct.propsArray 
        callStack = {} if atRoot
        addTo(callStack, prop)
        val[prop.name] = {}
        val[prop.name] = prop.buildJSON(callStack) unless exceededCallStack(callStack, prop)
        if struct.parent? 
          sp = map[struct.parent]
          if sp? 
            addStruct(callStack, sp , val, atRoot, map)

    atRoot = true unless callStack
    callStack = callStack || {}
    returnVal    
    if @ref
      struct = @service.structMap[@ref]
      val = {}      
      addStruct(callStack, struct, val, atRoot, @service.structMap)
      returnVal = val
    else if @enumRef
      enumObj = @service.enumMap[@enumRef]
      returnVal = enumObj.values[0].name      
    else if @type == "list"
      val = []      
      callStack = {} if atRoot      
      addTo(callStack, @listPropObj)
      val.push @listPropObj.buildJSON(callStack) unless exceededCallStack(callStack, @listPropObj)
      returnVal = val
    else if @type == "map"
      val = {}
      callStack = {} if atRoot
      addTo(callStack, @listPropObj)
      val[@keyType] = {}
      val[@keyType] = @listPropObj.buildJSON(callStack) unless exceededCallStack(callStack, @listPropObj)
      returnVal = val
    else      
      returnVal = @getPrimativeVal()
    returnVal
    
  getPrimativeVal: () ->
    val = @type
    switch @type
      when "datetime" then val = "2013-09-01T00:00:00.000-05:00"
      when "bool" then val = true
      when "byte" then val = 1
      when "int8" then val = 1
      when "int16" then val = 1
      when "int32" then val = 1
      when "int64" then val = "1"
      when "float32" then val = 3.14
      when "float64" then val = 3.14159
      when "string" then val = "string"
      when "decimal" then val = "3.2415"
      when "char" then val = "A"
      when "binary" then val = "YXNhZGFzZAo="
      else val = @type
    val
    
  typeToString: () ->    
    typeVal = @type
    if @ref
      typeVal = @ref
    else if @enumRef
      typeVal = @enumRef
    else if @type == "list"
      typeVal += "<" + @listPropObj.toString() + ">"
    else if @type == "map"      
      typeVal = @type
      typeVal += "<" + @keyType + ", " + @listPropObj.toString() + ">"      
    typeVal
    
  toString: () ->
    str = ""
    if @name
      str = @typeToString() + " " + @name
    else
      str = @typeToString()
    str    
  
class BabelHttp
  Shred: null
  shred: null
  content: null

  constructor: ->    
    @Shred = require "./shred"
    @shred = new @Shred()
    identity = (x) => x
    toString = (x) => x.toString()
      
    if typeof window != 'undefined'
      @content = require "./shred/content"
      @content.registerProcessor(
        ["application/json; charset=utf-8","application/json","json"], { parser: (identity), stringify: toString })
    else
      @Shred.registerProcessor(
        ["application/json; charset=utf-8","application/json","json"], { parser: (identity), stringify: toString })

  execute: (obj) ->
    @shred.request obj      