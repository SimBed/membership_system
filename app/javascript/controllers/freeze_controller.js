import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source", "hideable", "doctorNote" ]
  static values = { medical: Boolean, price: Number }

  // connect() {
  //   console.log(this.priceValue)
  // }

  copy_to_razorpay_form() {
    const dateInput = document.getElementById("start_date");
    dateInput.setAttribute("value", this.sourceTarget.value);
  }

  dynamic_end_date() {
    // dynamically make freeze period default to 14 days
    let start_date_string = document.getElementById("freeze_start_date").value;
    let start_date = new Date(start_date_string);
    // previous unnecessarily complicated way
    // surprisingly awkward to manage date objects in javascript
    // let start_date_array = start_date_string.split('-');
    // https://attacomsian.com/blog/javascript-date-add-days
    // let start_date = new Date(start_date_array[0], start_date_array[1] - 1, start_date_array[2]);
    // getDate gets the day of the month of the data. setDate knows to add to the month of the date if the number of days being set goes over the end of the month
    // this mutates start_date
    start_date.setDate(start_date.getDate() + (14 -1));
    let end_date_string = start_date.toISOString().slice(0,10); // only need the first ten characters '01-05-2023', not the subsequent time details
    document.getElementById("freeze_end_date").value = end_date_string;
  }
  
  toggle_medical() {
    this.medicalValue = !this.medicalValue
    this.doctorNoteTarget.hidden = !this.medicalValue;
    this.doctorNoteValue = false;
    document.getElementById('freeze_doctor_note').checked = false;
    if (this.doctorNoteValue != true) {
      document.getElementById('freeze_payment_attributes_amount').value = this.priceValue;
      }      
    this.hideableTarget.hidden = false;
  }
    
  toggle_doctor_note() {
    this.doctorNoteValue = !this.doctorNoteValue;
    this.hideableTarget.hidden = this.doctorNoteValue;
    if (this.doctorNoteValue == true) {
      document.getElementById('freeze_payment_attributes_amount').value = 0;
    } else {
      document.getElementById('freeze_payment_attributes_amount').value = this.priceValue;
    }
  }

}