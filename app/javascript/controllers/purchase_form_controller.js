import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "clientSearch", "clientSelect", 'product', "renewalDiscount", "statusDiscount", "commercialDiscount", "discretionDiscount", "oneOffDiscount", "dop", "priceId", "basePrice", "charge"]
  static values = { discountUrl: String, dopChangeUrl: String, clientFilterUrl: String }


  connect() {
    console.log(this.priceIdTarget)
    console.log(this.basePriceTarget)
    console.log(this.chargeTarget)
    console.log(this.dopTargets[2].value)
  }
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

  // when the dop changes both he the change and the date_change method are called. However, we need the date_change action to complete in its entirety
  // (which finishes with populating the discount dropdowns) before starting the change method, so set a short timeout on the change method,
  // before it starts so the date_change method will have time to finish before the change method starts. Improve this as there must be a better way.
  change() {
    setTimeout(() => this.load(), 100)
  }
  
  date_change() {
    this.date_change_load();
  }

  // repopulate the discount dropdowns based on the discounts available at the new date
  date_change_load(){
    let renewal_discount_select = this.renewalDiscountTarget    
    let status_discount_select = this.statusDiscountTarget
    let commercial_discount_select = this.commercialDiscountTarget
    let discretion_discount_select = this.discretionDiscountTarget
    let oneoff_discount_select = this.oneOffDiscountTarget
    let queryHash = {
      renewal_discount_id: renewal_discount_select.value,
      status_discount_id: status_discount_select.value,
      commercial_discount_id: commercial_discount_select.value,
      discretion_discount_id: discretion_discount_select.value,
      oneoff_discount_id: oneoff_discount_select.value,
      // product_id: this.productTarget.value || 0,
      dop_1i: this.dopTargets[0].value,
      dop_2i: this.dopTargets[1].value,
      dop_3i: this.dopTargets[2].value  
    }
    fetch(this.dopChangeUrlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => {
        renewal_discount_select.innerHTML = JSON.parse(s).renewal;
        status_discount_select.innerHTML = JSON.parse(s).status;
        commercial_discount_select.innerHTML = JSON.parse(s).commercial;
        discretion_discount_select.innerHTML = JSON.parse(s).discretion;
        oneoff_discount_select.innerHTML = JSON.parse(s).oneoff;
      })
    });    
    
  }

  // repopulate the price related items based on the new product/discount/date (noting the discounts may have already auto-changed if the changed item was dop)
  load() {
    let priceIdEl = this.priceIdTarget;
    let basePriceEl = this.basePriceTarget;
    let chargeEl = this.chargeTarget;
    // let basePriceEl = document.getElementById('purchase_base_price');
    // let paymentEl = document.getElementById('purchase_charge');
    // let priceIdEl = document.getElementById('purchase_price_id');
    let queryHash = {
      renewal_discount_id: this.renewalDiscountTarget.value,
      status_discount_id: this.statusDiscountTarget.value,
      commercial_discount_id: this.commercialDiscountTarget.value,
      discretion_discount_id: this.discretionDiscountTarget.value,
      oneoff_discount_id: this.oneOffDiscountTarget.value,
      product_id: this.productTarget.value || 0
    }
    // console.log(this.discountUrlValue + '?' + new URLSearchParams(queryHash))
    fetch(this.discountUrlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => {console.log(s);
        priceIdEl.value = JSON.parse(s).base_price_id;
        basePriceEl.value = JSON.parse(s).base_price_price;
        chargeEl.value = JSON.parse(s).payment_after_discount;})
    });
  }
}