import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "clientSearch", "clientSelect", 'product', "renewalDiscount", "statusDiscount", "commercialDiscount", "discretionDiscount", "oneOffDiscount", "dop", "priceId", "basePrice", "charge"]
  static values = { discountUrl: String, dopChangeUrl: String, clientFilterUrl: String }

  // connect() {
  //   console.log(this.priceIdTarget)
  //   console.log(this.basePriceTarget)
  //   console.log(this.chargeTarget)
  //   console.log(this.dopTargets[2].value)
  // }

  client_search() {
    let client_dropdown = this.clientSelectTarget

    let queryHash = { select_client_name: this.clientSearchTarget.value }  
    fetch(this.clientFilterUrlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => {console.log(s);
        client_dropdown.selectedIndex = JSON.parse(s).selected_client_index;
      })
    });    
  }
  
  field_change(){
    let renewal_discount_select = this.renewalDiscountTarget    
    let status_discount_select = this.statusDiscountTarget
    let commercial_discount_select = this.commercialDiscountTarget
    let discretion_discount_select = this.discretionDiscountTarget
    let oneoff_discount_select = this.oneOffDiscountTarget
    let priceIdEl = this.priceIdTarget;
    let basePriceEl = this.basePriceTarget;
    let chargeEl = this.chargeTarget;  
    let queryHash = {
      renewal_discount_id: renewal_discount_select.value,
      status_discount_id: status_discount_select.value,
      commercial_discount_id: commercial_discount_select.value,
      discretion_discount_id: discretion_discount_select.value,
      oneoff_discount_id: oneoff_discount_select.value,
      product_id: this.productTarget.value || 0,
      dop_1i: this.dopTargets[0].value,
      dop_2i: this.dopTargets[1].value,
      dop_3i: this.dopTargets[2].value  
    }
    fetch(this.dopChangeUrlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => {
        console.log(s);
        renewal_discount_select.innerHTML = JSON.parse(s).renewal;
        status_discount_select.innerHTML = JSON.parse(s).status;
        commercial_discount_select.innerHTML = JSON.parse(s).commercial;
        discretion_discount_select.innerHTML = JSON.parse(s).discretion;
        oneoff_discount_select.innerHTML = JSON.parse(s).oneoff;
        priceIdEl.value = JSON.parse(s).base_price_id;
        basePriceEl.value = JSON.parse(s).base_price_price;
        chargeEl.value = JSON.parse(s).payment_after_discount;        
      })
    });    
  }

  // when the dop changes both the change and the date_change method are called. However, we need the date_change action to complete in its entirety
  // (which finishes with populating the discount dropdowns) before starting the change method, so set a short timeout on the change method,
  // before it starts so the date_change method will have time to finish before the change method starts.
  // change() {
  //   setTimeout(() => this.load(), 100)
  // }
  
}