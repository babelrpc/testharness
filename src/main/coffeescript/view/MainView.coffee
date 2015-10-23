class MainView extends Backbone.View
  
  events: {
    "change #serviceSelect": "selectService"
  }
  
  initialize: ->
    $(@el).html(Handlebars.templates.main(@model))
  clear: ->
    $(@el).html = ''
    
  render: ->
    
  selectService: (e) ->
    val = $(e.currentTarget).val()
    Backbone.history.navigate("#srv/" + val, {trigger: true});        