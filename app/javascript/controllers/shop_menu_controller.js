import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "trialBtn", "unlimitedProduct", "fixedProduct", "fixedBtn", "unlimitedBtn", "fixedStatement", "unlimitedStatement" ] 
  static values = { index: String, trialPrice: String, defaultProductType: String }

  // set text of razorpay button, which by default razorpay forces to be 'Pay Now'
  // note the razorpay submit button element is created by the razorpay script, so can't directly add a data-target to it
  connect() {
    if (this.hasTrialBtnTarget) { this.trialBtnTarget.getElementsByClassName("razorpay-payment-button")[0].value = this.trialPriceValue };
    if (this.defaultProductTypeValue == 'unlimited') {    
      this.unlimitedBtnTarget.classList.add('current');
    } else {
      this.fixedBtnTarget.classList.add('current');
    }
  }

  showUnlimited() {
    this.indexValue = 'unlimited'
    this.showCorrectProducts()
    this.showCorrectStatement()
    this.unlimitedBtnTarget.classList.add('current'); 
    this.fixedBtnTarget.classList.remove('current'); 
  }

  showFixed() {
    this.indexValue = 'fixed'
    this.showCorrectProducts()
    this.showCorrectStatement()
    this.fixedBtnTarget.classList.add('current'); 
    this.unlimitedBtnTarget.classList.remove('current');   
  }  

  // be aware Stimulus invokes each change callback AFTER THE CONTROLLER IS INITIALIZED (as well as any time its associated data attribute changes)
  // indexValueChanged() {
  //   console.log(this.indexValue)
  //   this.showCorrectProducts()
  // }

  showCorrectProducts() {
    this.unlimitedProductTargets.forEach((el) => {
      el.hidden = this.indexValue != 'unlimited'
    })
    this.fixedProductTargets.forEach((el) => {
      el.hidden = this.indexValue != 'fixed'
    })
  }  

  showCorrectStatement() {
    this.unlimitedStatementTarget.hidden = this.indexValue != 'unlimited' 
    this.fixedStatementTarget.hidden = this.indexValue != 'fixed'
  }  

}