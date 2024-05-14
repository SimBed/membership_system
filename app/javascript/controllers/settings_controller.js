import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="blast"
export default class extends Controller {
  static targets = [ "scopeSelector", "settingsScope", "settingsScopeTimetable" ]
  static classes = [ "toggle" ]
  static values = { recipientNumber: Number }
  
  connect() {
  }

  change(event) {
    console.log(this.settingsScopeClient);
    console.log(event.target.value);
    this.settingsScopeTargets.forEach((settingScope)=> {
      settingScope.classList.remove('live', 'd-flex', 'flex-column')
    })
    // element.classList.add('live', 'd-flex', 'flex-column')
    this.targets.find(`settingsScope${event.target.value}`).classList.add('live');
  }

}
