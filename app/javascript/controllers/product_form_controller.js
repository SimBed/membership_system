import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["maxClassesContainer", "maxClasses", "unlimited"]

  connect() {
  }

  unlimitedToggle() {
    if (this.unlimitedTarget.checked) {
      this.maxClassesTarget.value = 1000;
      this.maxClassesContainerTarget.hidden = true;
    } else {
      this.maxClassesTarget.value = 1;      
      this.maxClassesContainerTarget.hidden = false;
    }
  }

}
