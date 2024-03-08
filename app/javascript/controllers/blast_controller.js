import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="blast"
export default class extends Controller {
  static targets = [ "blastButton" ]
  static classes = [ "toggle" ]
  connect() {
    console.log('hih')
  }

  toggle_blast_ready() {
    this.blastButtonTarget.classList.toggle(this.toggleClass)
  }

}
