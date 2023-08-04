// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import "../scss/application.scss";
// https://stackoverflow.com/questions/60727460/using-bootstrap-icons-in-rails-6-with-webpacker
import "bootstrap-icons/font/bootstrap-icons.css"

import Rails from "@rails/ujs"; global.Rails = Rails;
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"
import '../js/bootstrap_js_files.js'
import '../js/headroom.js'
import "jquery"
import "chartkick/chart.js"

Rails.start()
Turbolinks.start()
ActiveStorage.start()
