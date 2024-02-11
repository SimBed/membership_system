import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="package-policy"
export default class extends Controller {
  static targets = [ "btnGroup", "btnPt", "contentGroup", "contentPt" ]
  static values = { defaultPolicy: String }

  connect() {
    console.log(this.defaultPolicyValue)
    if (this.defaultPolicyValue == 'pt') {    
      this.btnPtTarget.classList.add('current');
    } else {
      this.btnGroupTarget.classList.add('current');
    }    
  }

  showGroup() {
    this.contentGroupTarget.hidden = false
    this.contentPtTarget.hidden = true
    this.btnGroupTarget.classList.add('current'); 
    this.btnPtTarget.classList.remove('current');   
  }

  showPt() {
    this.contentGroupTarget.hidden = true
    this.contentPtTarget.hidden = false
    this.btnGroupTarget.classList.remove('current'); 
    this.btnPtTarget.classList.add('current');   
  }
}
