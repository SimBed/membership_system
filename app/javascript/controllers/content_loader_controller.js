import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, capacity: String }

  change() {
    // console.log(this.urlValue);
    this.load()
  }

  load() {
    let selected_instructor = document.getElementById("wkclass_instructor_id");
    let selected_workout = document.getElementById("wkclass_workout_id");
    let instructor_rate_select = document.getElementById('wkclass_instructor_rate_id')
    let queryHash = {
      selected_instructor_id: selected_instructor.value,
      selected_workout_id: selected_workout.value,
    }
    if (this.capacityValue == 'yes') {this.get_max_capacity(selected_workout)}
    // https://stackoverflow.com/questions/35038857/setting-query-string-using-fetch-get-request/58437909#58437909
    // AlexChaffee @ https://stackoverflow.com/questions/40385133/retrieve-data-from-a-readablestream-object
    // console.log(this.urlValue + '?' + new URLSearchParams(queryHash))
    fetch(this.urlValue + '?' + new URLSearchParams(queryHash))
    .then(function(response) {
      response.text().then((s) => instructor_rate_select.innerHTML = s)
    });
  }

  // max-capacity field based on workout selected
  get_max_capacity(selected_workout) {
    // let selected_workout = document.getElementById("wkclass_workout_id");
    let capacity = selected_workout.options[selected_workout.selectedIndex].dataset.capacity
    document.getElementById('wkclass_max_capacity').value = parseInt(capacity);
  }
}