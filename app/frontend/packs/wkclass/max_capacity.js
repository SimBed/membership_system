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
  selection_instructor = document.getElementById("wkclass_instructor_id");
  selection_workout = document.getElementById("wkclass_workout_id");
  // selection_text = selection.options[selection.selectedIndex].text;  
    $.ajax({
        url:  '/wkclasses/instructor',
        type: 'get',
        data: { selected_instructor_id: selection_instructor.value,
                selected_workout_id: selection_workout.value }
    });
}

// max-capacity field based on workout selected
function get_max_capacity() {
  var sel = document.getElementById('wkclass_workout_id');
  var text = sel.options[sel.selectedIndex].text
  switch (text.substring(0, 3)) {
    case 'PT ':
    case 'InB':
      max_capacity = 1;
      break;
    case 'PSM':
    case 'Mat':
      max_capacity = 6;
      break;
    case 'Eve':
      max_capacity = 500;
      break;
    default:
      max_capacity = 12;
      break;
  }
  document.getElementById('wkclass_max_capacity').value = max_capacity;
}



