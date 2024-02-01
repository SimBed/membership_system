import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "trial-button" ] 
  static values = { trialPrice: Number }

  // set text of razorpay button, which by default razorpay forces to be 'Pay Now'
  connect() {
    console.log(this.trialPriceValue);
    // this.trialButtonTarget.getElementsByClassName("razorpay-payment-button")[0].value = this.trialPriceValue; 
  } 
  // var trialbtn = document.getElementById("trial-btn")
  // if (trialbtn) { document.getElementById("trial-btn").getElementsByClassName("razorpay-payment-button")[0].value= '<%= rupees(@trial_price) %>' }
  // Click on option wanted to be visible as default
  // <% if @last_product_fixed %>
  //   document.getElementById("Flex_btn").click();
  // <% else %>
  //   document.getElementById("Unlimited_btn").click();
  // <% end %>


}