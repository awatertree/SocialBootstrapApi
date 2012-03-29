require('auth-base/templates/app')
require('auth-base/templates/login')
require('auth-base/templates/home')

window.Auth = Em.Application.create

Auth.HomeView = Em.View.create
  templateName: 'home'

Auth.LoginView = Em.View.create
  tagName: 'form'
  action: '#'
  templateName: 'login'

  UserNameText: Em.TextField.extend
    init: ->
      @_super()
      @setPath('parentView.userName', this)
      
    insertNewline: -> @getPath('parentView').submit()

  PasswordText: Em.TextField.extend
    init: ->
      @_super()
      @setPath('parentView.password', this)
      
    type: 'password'
    insertNewline: -> @getPath('parentView').submit()

  submit: ->
    console.log 'user.name'.loc()
    console.log Auth.appManager
    console.log @getPath('userName.value')
    console.log @getPath('password.value')
    Auth.appManager.send 'login', { userName: @getPath('userName.value'), password: @getPath('password.value') }
    console.log 'after send'
    #, @getPath('userName.value'), @getPath('password.value')

Auth.AppView = Em.View.create
  templateName: 'app'

Auth.loginManager =
  authenticate: (userName, password, isLogout) ->
    xhr = $.ajax '/auth/customers', {
      username: userName,
      password: password,
      dataType: 'json',
      success: (data) ->
        console.log Auth.appManager.currentState
        Auth.appManager.send 'authSuccessful', { userName: userName }
        console.log 'huh?'
        
      error: (xhr) ->
        if isLogout
          Auth.appManager.send 'logout'
    }
    
  logout: ->
    if ($.browser.msie)
      document.execCommand 'ClearAuthenticationCache'
      Auth.appManager.send 'logout'
    else
      Auth.loginManager.authenticate("_logout_", "_logout_", true)
        
Auth.userController = Em.Object.create
  content: {}

Auth.authController = Em.Object.create
  newLoginSession: ->
    @set('hasError', false)
    @set('errorMessage', null)

  loginFailed: (errorMessage) ->
    @set('hasError', true)
    @set('errorMessage', errorMessage)

Auth.appManager = Em.StateManager.create

  rootElement: '#auth-app'
    
  start: 'notLoggedIn'
  
  notLoggedIn: Em.State.create

    initialState: 'awaitingUserInput'

    enter: ->
      Auth.authController.newLoginSession()
      
    login: (manager, context) ->
      console.log "logina event #{context.userName}:#{context.password}"
      Auth.userController.set 'userName', context.userName
      Auth.userController.set 'password', context.password
      manager.goToState 'authenticatingUser'
      console.log 'after'

    awaitingUserInput: Em.ViewState.create
    
      view: Auth.LoginView
      
      enter : (manager) ->
        @_super(manager)
        console.log "at awaiting user input"
        console.log 'ack'

    authenticatingUser: Em.State.create
      enter: ->
        uc = Auth.userController
        Auth.loginManager.authenticate uc.get('userName'), uc.get('password')

      authSuccessful: (manager) ->
        Auth.userController.set 'password', ''
        console.log 'before loggedin'
        manager.goToState 'loggedIn'
        console.log 'after loggedin'

      authFailed: (errorMessage) ->
        Auth.authController.loginFailed errorMessage
        @goToState 'awaitingUserInput'


  loggedIn: Em.State.create
  
    initialState: 'viewingDashboard'

    viewingDashboard: Em.ViewState.create
      view: Auth.AppView

    logout: (manager) ->
      manager.goToState 'notLoggedIn'

# View requests login:
# Auth.statechart.sendAction 'login', @get 'userName', @get 'password'

# Login Manager successful login where user is loaded into data store:
# Auth.statechart.sendAction 'authSuccessful', user

# Login Manager auth failed where errorMessage is the reason Server Gave
# Auth.statechart.sendAction 'authFailed', errorMessage

# Logout Button View does something like this:
# Auth.statechart.sendAction 'logout'
