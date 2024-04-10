import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "hideable", "doctorNote", 'startDate', 'endDate', 'paymentAmount', 'razStartDate' ]
  static values = { medical: Boolean, price: Number }

  // connect() {
  //   console.log(this.paymentAmountTarget)
  // }

  copy_to_razorpay_form() {
    this.razStartDateTarget.setAttribute("value", this.startDateTarget.value);
  }

  dynamic_end_date() {
    // dynamically make freeze period default to 14 days
    let start_date_string = this.startDateTarget.value;
    let start_date = new Date(start_date_string);
    // getDate gets the day of the month of the date.
    // setDate knows to add to the month of the date if the number of days being set goes over the end of the month.
    // this mutates start_date
    start_date.setDate(start_date.getDate() + (14-1));
    let end_date_string = start_date.toISOString().slice(0,10); // only need the first ten characters '01-05-2023', not the subsequent time details
    this.endDateTarget.value = end_date_string;
  }
  
  toggle_medical() {
    this.medicalValue = !this.medicalValue
    this.doctorNoteTarget.hidden = !this.medicalValue;
    // always start with doctor's not unchecked. Either 1) medical has just been unchecked, (in which case doctors note must be unchecked), or
    // 2) medical has just been checked, unhiding a medical checkbox in its (unchecked) starting position
    this.doctorNoteValue = false;
    this.doctorNoteTarget.children[2].checked = false; // targets the input checkbox of the explicitly targeted div
    // if (this.doctorNoteValue != true) {
    // when there is no doctors note, there must be a payment and the payment details must be exposed
    this.paymentAmountTarget.value = this.priceValue;
      // document.getElementById('freeze_payment_attributes_amount').value = this.priceValue;
    // }
    this.hideableTarget.hidden = false;
  }
  
  toggle_doctor_note() {
    this.doctorNoteValue = !this.doctorNoteValue;
    this.hideableTarget.hidden = this.doctorNoteValue;
    if (this.doctorNoteValue == true) {
      this.paymentAmountTarget.value = 0;
    } else {
      this.paymentAmountTarget = this.priceValue;
    }
  }
  
}

// previous unnecessarily complicated way to manage date objects in javascript
// https://attacomsian.com/blog/javascript-date-add-days
// let start_date_array = start_date_string.split('-');
// let start_date = new Date(start_date_array[0], start_date_array[1] - 1, start_date_array[2]);