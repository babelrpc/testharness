class BabelUi extends Backbone.Router

  # Defaults
  dom_id: "babel_ui"
  
  routes: {
    "srv/:srv/:meth":"showService"
    "srv/:srv":"showService"
    "*actions": "defaultRoute"
  }
  
  showService: (service, method) ->

    @service = service
    @method = method
    @options.success = => @loadService()    
    @load()
    
  loadService: () ->

    success = (srv) => @renderService(srv, @method)    
    @api.loadService(@service, success)    
    
  defaultRoute: ->
    
    @options.success = => @renderMain()
    @load()        
  
  initialize: (options={}) ->
    
    Handlebars.registerHelper('ifNotLast', (array, currentIndex, options) ->      
        if currentIndex != array.length - 1
          return options.fn(this)
    )    
    
    if options.dom_id?
      @dom_id = options.dom_id
      delete options.dom_id
    
    $('body').append('<div id="' + @dom_id + '"></div>') if not $('#' + @dom_id)?    
    @options = options    
  
  load: () ->    
    url = @options.url
    if url?
      if url.indexOf("http") isnt 0
        url = @buildUrl(window.location.href.toString(), url)
    else
      url = @getBaseUrl()
      url = url.replace("index.html", "") + "babel.json"
    
    @options.url = url
    @api = new BabelApi(url, @options)
    @api.homeUrl = @getBaseUrl()
    @api  
    
  renderMain:() ->
    
    @mainView?.clear()
    @mainView = new MainView({model:@api, el: $('#' + @dom_id)})
    @mainView.render()    
    
  renderService: (srv, methodName) ->

    if !methodName?
      methodName = srv.methodArray[0].name
      @method = methodName
    @harnessView?.clear()        
    @harnessView = new HarnessView({model: {service:srv, method:srv.methodMap[methodName], baseUrl:@getBaseUrl(), structs:srv.methodMap[methodName].getStructs(), enums:srv.methodMap[methodName].getEnums()}, el: $('#' + @dom_id)})
    @harnessView.render()
    
  buildUrl: (base, url) ->
    parts = base.split("/")
    base = parts[0] + "//" + parts[2]
    if url.indexOf("/") is 0
      base + url
    else
      base + "/" + url
      
  getBaseUrl: () ->
    urlVals = window.location.href.toString().split "#"
    urlVals[0]
    
window.BabelUi = BabelUi    