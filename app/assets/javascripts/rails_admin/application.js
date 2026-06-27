// rails_admin JS is handled via webpack (see app/client/entry/rails_admin.js)
// This file overrides the gem's application.js.erb to prevent Sprockets
// from requiring webpack-only files (abstract-select, filtering-select, etc.)

//= require rails-ujs
//= require rails_admin/jquery3
//= require jquery_nested_form
//= require rails_admin/flatpickr-with-locales
//= require rails_admin/popper
//= require rails_admin/bootstrap
