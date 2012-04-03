require('auth-base/core')
require('auth-base/i18n')

$(document).ready ->
  Em.run -> 
    Auth.appManager.goToState('notLoggedIn')
