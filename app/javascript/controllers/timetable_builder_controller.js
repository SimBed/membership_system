import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timetable-builder"
export default class extends Controller {
  static values = { cssclass: String, display: String }

  // Switch between edit and preview mode
  toggle_visibility(){
    var elements = document.getElementsByClassName(this.cssclassValue);
    var btnValue = document.getElementById("btnPreview");
    var n = elements.length;
    console.log(n);
      for (var i = 0; i < n; i++) {
      var e = elements[i];
      if(window.getComputedStyle(e, null).display == this.displayValue) {
        e.style.display = 'none';
      } else {
        e.style.display = this.displayValue;
      }
    }
    if(elements[0].style.display == 'none') {
      btnValue.innerText="Edit Mode...";
    } else {
      btnValue.innerText="Preview...";
      }
  }

}
