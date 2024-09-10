import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "blastButton" ]
  static classes = [ "toggle" ]
  static values = { recipientNumber: Number }
  
  connect() {
  }

  toggle_blast_ready() {
    this.blastButtonTarget.classList.toggle(this.toggleClass)
  }

  // https://dev.to/software_writer/how-to-show-a-delete-confirmation-dialog-in-rails-using-stimulus-17i
  confirm(event) {
    let confirmation_message = `The notification will be issued to all ${this.recipientNumberValue} recipients. You may experience a lag if the recipient size is large. Are you sure?`
    let confirmed = confirm(confirmation_message)

    // ie if cancel button is clicked do nothing, otherwise continue in the normal way when a button is clicked
    if(!confirmed) {
      event.preventDefault()
    }
  }

}
