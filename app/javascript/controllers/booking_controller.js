import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "bookingDay", "dayButton" ]
  static values = { day: String }

  // https://stimulus.hotwired.dev/reference/actions action parameters
  change_day( event ) {
    console.log(this.bookingDayTargets.length)
    this.dayButtonTargets.forEach((btn)=> {
      btn.classList.remove('live')
    })
    event.target.classList.add('live')
    this.bookingDayTargets.forEach((day)=> {
      day.classList.remove('live')
    })
    let selected_day = event.params['day'];
    // doesn't seem to be a nice stimulus-style way of doing this (would have to rigidly pre-define a fixed load of static targets)
    let bookables = document.querySelectorAll(`.booking-day${selected_day}`);
    bookables.forEach((bookable)=> {
      bookable.classList.add('live');
    })    
  }
}