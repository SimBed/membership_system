// max-capacity field based on workout selected

document.getElementById('wkclass_workout_id').onchange =  function () {
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
  // alert (text.substring(0, 3));
  document.getElementById('wkclass_max_capacity').value = max_capacity;
}
