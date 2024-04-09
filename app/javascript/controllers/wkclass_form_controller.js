import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "workout", "instructor", "instructorRate", "maxCapacity" ]
  static values = { url: String, capacity: String }

  change() {
    console.log(this.urlValue);
    console.log(this.instructorTarget.value);
    console.log(this.instructorRateTarget.innerHTML);
    console.log(this.workoutTarget.value);
    console.log(this.capacityValue);
    this.load()
  }

  load() {
    let queryHash = {
      selected_instructor_id: this.instructorTarget.value,
      selected_workout_id: this.workoutTarget.value
    }
    if (this.capacityValue == 'yes') {this.get_max_capacity()}
    // https://stackoverflow.com/questions/35038857/setting-query-string-using-fetch-get-request/58437909#58437909
    // AlexChaffee @ https://stackoverflow.com/questions/40385133/retrieve-data-from-a-readablestream-object
    // console.log(this.urlValue + '?' + new URLSearchParams(queryHash))
    let instructor_rate_select = this.instructorRateTarget
    fetch(this.urlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => instructor_rate_select.innerHTML = s)
    });
  }

  get_max_capacity() {
    let capacity = this.workoutTarget.options[this.workoutTarget.selectedIndex].dataset.capacity
    this.maxCapacityTarget.value = parseInt(capacity);
  }
}