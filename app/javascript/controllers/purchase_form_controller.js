import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, dateurl: String, clientfilterurl: String }
  // static targets = [ "hideable" ] 

  clientsearch() {
    let search_client_name = document.getElementById("search_client_name").value;    
    let client_select = document.getElementById('purchase_client_id')

    let queryHash = { select_client_name: search_client_name }  
    fetch(this.clientfilterurlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => {console.log(s);
        client_select.selectedIndex = JSON.parse(s).clientindex;
      })
    });    
  }

  // when the date changes we need the date_change action to complete in its entirety (which finishes with populating the discount dropdowns)
  // before starting the next action so set a short timeout. Improve this as there must be a better way.
  change() {
    setTimeout(() => this.load(), 100)
  }
  
  date_change() {
    this.date_change_load();
  }

  date_change_load(){
    let selected_renewal_discount_id = document.getElementById("purchase_renewal_discount_id").value || 0;
    let selected_status_discount_id =  document.getElementById("purchase_status_discount_id").value || 0;
    let selected_oneoff_discount_id = document.getElementById("purchase_oneoff_discount_id").value || 0;
    let selected_commercial_discount_id = document.getElementById("purchase_commercial_discount_id").value || 0;
    let selected_discretion_discount_id = document.getElementById("purchase_discretion_discount_id").value || 0;
    let selected_product_id = document.getElementById("purchase_product_id").value || 0;
    let selected_dop_1i = document.getElementById("purchase_dop_1i").value;
    let selected_dop_2i = document.getElementById("purchase_dop_2i").value;
    let selected_dop_3i = document.getElementById("purchase_dop_3i").value;
    let renewal_discount_select = document.getElementById('purchase_renewal_discount_id')    
    let status_discount_select = document.getElementById('purchase_status_discount_id')    
    let oneoff_discount_select = document.getElementById('purchase_oneoff_discount_id')    
    let queryHash = {
      selected_renewal_discount_id: selected_renewal_discount_id,
      selected_status_discount_id: selected_status_discount_id,
      selected_oneoff_discount_id: selected_oneoff_discount_id,
      selected_commercial_discount_id: selected_commercial_discount_id,
      selected_discretion_discount_id: selected_discretion_discount_id,
      selected_product_id: selected_product_id,
      selected_dop_1i: selected_dop_1i,
      selected_dop_2i: selected_dop_2i,
      selected_dop_3i: selected_dop_3i  
    }
    fetch(this.dateurlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => {
        renewal_discount_select.innerHTML = JSON.parse(s).renewal;
        status_discount_select.innerHTML = JSON.parse(s).status;
        oneoff_discount_select.innerHTML = JSON.parse(s).oneoff;
      })
    });    
    
  }

  load() {
    let selected_renewal_discount_id = document.getElementById("purchase_renewal_discount_id").value || 0;
    let selected_status_discount_id =  document.getElementById("purchase_status_discount_id").value || 0;
    let selected_oneoff_discount_id = document.getElementById("purchase_oneoff_discount_id").value || 0;
    let selected_commercial_discount_id = document.getElementById("purchase_commercial_discount_id").value || 0;
    let selected_discretion_discount_id = document.getElementById("purchase_discretion_discount_id").value || 0;
    let selected_product_id = document.getElementById("purchase_product_id").value || 0;
    let basePriceEl = document.getElementById('purchase_base_price');
    let paymentEl = document.getElementById('purchase_charge');
    let priceIdEl = document.getElementById('purchase_price_id');
    let queryHash = {
      selected_renewal_discount_id: selected_renewal_discount_id,
      selected_status_discount_id: selected_status_discount_id,
      selected_oneoff_discount_id: selected_oneoff_discount_id,
      selected_commercial_discount_id: selected_commercial_discount_id,
      selected_discretion_discount_id: selected_discretion_discount_id,
      selected_product_id: selected_product_id
    }
    fetch(this.urlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => {console.log(s);
        basePriceEl.value = JSON.parse(s).base_price_price;
                                   paymentEl.value = JSON.parse(s).payment_after_discount;
                                   priceIdEl.value = JSON.parse(s).base_price_id})
    });
  }
  
  // adjust_restart() {
  //   this.hideableTargets.forEach((el) => {
  //     el.hidden = !el.hidden
  //   });    
  // }

}