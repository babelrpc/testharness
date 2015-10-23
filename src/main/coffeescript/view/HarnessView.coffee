class HarnessView extends Backbone.View
  events: {
    'click .submit': 'submitMethod',
    'click .reset': 'resetMethod'
    'click #headersLink': 'toggleHeaders'
  }  
  initialize: ->
    $(@el).html(Handlebars.templates.harness(@model))
    
  clear: ->    
    $(@el).html = ''    
    @undelegateEvents();
          
  render: ->

    @resetMethod()
    $('#headersPanel').hide()
    $('#harnessTabs a[href="#home"]').tab('show')
    $('#trymeTabs a[href="#jsonpanel"]').tab('show')
    $('#objectTabs a[href="#structpanel"]').tab('show')
    
  submitMethod: (e) ->
    e?.preventDefault
    headersForm = $('.headersForm', $(@el))
    headers = []
    for o in headersForm.find("input.header")
      if o.value then headers.push {name:o.name, val:o.value}      
    
    url = headersForm.find("input.serviceUrl:first").val()
    content = $('.contentForm', $(@el)).find("textarea:first").val()          
    success = (json, success) => @callResult(json, success)      
    @model.method.perform(url, headers, content, success)
    false
    
  resetMethod: (e) ->
    e?.preventDefault   
    $('#postResult').html "No Results Yet!" 
    $('#postError').html ""
    $('#postErrorPanel').hide()
    form = $('.contentForm', $(@el))
    form.find("textarea:first").val(@model.method.sampleJSON)              
    
  callResult: (json, success) ->
    if success
      $('#postResult').html json
      $('#postErrorPanel').hide()
    else
      details = json.Details     
      delete json.Details 
      $('#postResult').html JSON.stringify(json, null, 2)
      $('#postError').html details
      $('#postErrorPanel').show()
    
    $('#harnessTabs a[href="#results"]').tab('show')
    
  toggleHeaders: (e) ->
    e.preventDefault 
    $('#headersPanel').toggle()
    false

