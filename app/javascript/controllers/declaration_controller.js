// think this is redundant (equivalent in signup controller)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "injuryNote", "submitButton" ]
  static values = { injury: Boolean }
  static classes = [ "toggle" ]  

  toggle_injury() {
    this.injuryValue = !this.injuryValue
    this.injuryNoteTarget.hidden = !this.injuryValue;
  }

  toggle_submit() {
    this.submitButtonTarget.classList.toggle(this.toggleClass)
  }  
}
