import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "transferBreakdown" ]

  toggle_breakdown() {
    this.transferBreakdownTarget.hidden = !this.transferBreakdownTarget.hidden
  }
}
