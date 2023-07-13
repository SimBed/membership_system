// populate instructor_rate dropdown based on workout/instructor combo selected (when instructor changes)
document.getElementById('wkclass_instructor_id').onchange =  function () {
  populate_instructor_rates_dropdown();
}

// populate instructor_rate dropdown based on workout/instructor combo selected (when workout changes)
document.getElementById('wkclass_workout_id').onchange =  function () {
  get_max_capacity();
  populate_instructor_rates_dropdown();
}

function populate_instructor_rates_dropdown() {
  selected_instructor = document.getElementById("wkclass_instructor_id");
  selected_workout = document.getElementById("wkclass_workout_id");
    $.ajax({
        url:  '/wkclasses/instructor',
        type: 'get',
        data: { selected_instructor_id: selected_instructor.value,
                selected_workout_id: selected_workout.value }
    });
}

// max-capacity field based on workout selected
function get_max_capacity() {
  selected_workout = document.getElementById("wkclass_workout_id");
  capacity = selected_workout.options[selected_workout.selectedIndex].dataset.capacity
  document.getElementById('wkclass_max_capacity').value = parseInt(capacity);
}



