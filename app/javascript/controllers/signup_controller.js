import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "medicalWarning", "doctorsClearance", "healthIssue", "noHealthIssues", "noHealthIssuesChbox", "terms", "paymentPolicy", "privacyPolicy", "indemnity", "injury", "injuryNote",
                     "medication", "medicationNote", "submitButton", "parq", "dob", "age" ]
  static values = { injury: Boolean, medication: Boolean }
  static classes = [ "disabled" ]

  connect() {
    this.ageTarget.value = this.calculateAge(this.dobTarget.value);
    this.toggle_medical_warning();
    this.toggle_no_health_issues();
    this.toggle_injury_note();
    this.toggle_medication_note();
    this.toggle_submit();
  }

  toggle_submit( event) {
    if (event != null) event.target.parentElement.parentElement.classList.toggle('border-danger');
    // event.target.parentElement.parentElement.classList.remove('border');
    // event.target.parentElement.parentElement.classlist.toggle('border');
    if (this.submitBtnDisabled()) {
      if (this.physicalActivityReady() && this.healthIssuesChecked() && this.allTermsAgreed()) 
        this.submitButtonTarget.classList.remove(this.disabledClass);}
    else if (!this.physicalActivityReady() || !this.healthIssuesChecked() || !this.allTermsAgreed())
      this.submitButtonTarget.classList.add(this.disabledClass);
   }

   toggle_no_health_issues() {
    if (this.anyHealthIssuesApply()) {
      if (!this.noHealthIssuesTarget.hidden) this.noHealthIssuesTarget.hidden = true;
      this.noHealthIssuesChboxTarget.required = false;
    }
    else if (this.noHealthIssuesTarget.hidden) {
      this.noHealthIssuesTarget.hidden = false;
      this.noHealthIssuesChboxTarget.required = true;
    }
    this.toggle_submit();
   }

   toggle_injury_note() {
     if (this.injuryTarget.checked) this.injuryNoteTarget.hidden = false;
     else {
      this.injuryNoteTarget.children[1].value = ''; // targets the textarea of the explicitly targeted div
      this.injuryNoteTarget.hidden = true;
     }
    }

  toggle_medication_note() {
    if (this.medicationTarget.checked) this.medicationNoteTarget.hidden = false;
    else {
    this.medicationNoteTarget.children[1].value = '';
    this.medicationNoteTarget.hidden = true;
    }
  }

  toggle_medical_warning() {
    var showMedicalValue = this.anyParqsApply();
    this.medicalWarningTarget.hidden = !showMedicalValue;
    this.doctorsClearanceTarget.required = showMedicalValue;
    // not essential but good practice to uncheck invisible checkbox
    if (!showMedicalValue) this.doctorsClearanceTarget.checked = false;
  }    

  anyParqsApply() {
    var isChecked = false;
    this.parqTargets.forEach((q)=> {
      if (q.checked) {
        isChecked = true;
        // cant break out of a forEach loop so dont break
      }
    })
    return isChecked;
  }    

  anyHealthIssuesApply() {
    var isChecked = false;
    this.healthIssueTargets.forEach((q)=> {
      if (q.checked) {
        isChecked = true;
      }
    })
    return isChecked;
  }    

  physicalActivityReady() {
    var anyParqsApply = this.anyParqsApply();
    if (!anyParqsApply || anyParqsApply && this.doctorsClearanceTarget.checked) {
      return true;
    }
    return false;
  }

  submitBtnDisabled() {
    return this.submitButtonTarget.classList.contains(this.disabledClass);
  }

  allTermsAgreed() {
    return this.termsTarget.checked && this.paymentPolicyTarget.checked && this.privacyPolicyTarget.checked && this.indemnityTarget.checked;
  }

  healthIssuesChecked() {
    // return this.noHealthIssuesTarget.children[1].children[0].children[1].checked || this.anyHealthIssuesApply();
    return this.noHealthIssuesChboxTarget.checked || this.anyHealthIssuesApply();
  }

  dob_change() {
    this.ageTarget.value = this.calculateAge(this.dobTarget.value)
  }

  calculateAge(dobInput) {
    var dob = new Date(dobInput);
    var currentDate = new Date();
    var timeDiff = currentDate - dob;
    // return Math.floor(timeDiff / (1000 * 60 * 60 * 24 * 365.25));
    return Math.floor((new Date() - new Date(dobInput).getTime()) / 3.15576e+10)
  }
  
}
