import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  connect() {
    const buttonContainerEl = document.querySelector(".button-container-full-width");
    const btns = document.querySelectorAll('button');
    const daycols = document.querySelectorAll('.booking-day');
    buttonContainerEl.addEventListener('click', (event) => {
      const day = event.target.dataset.day;
      // console.log(day)
      if(day) {
        btns.forEach((btn)=> {
          btn.classList.remove('live')
        })
        event.target.classList.add('live')
        daycols.forEach((daycol)=> {
          daycol.classList.remove('live')
        })
        const element = document.getElementById(day)
        element.classList.add('live')
      }      
      // this.updateDay(event);
    })    
  }

  // updateDay(event) {
  //   console.log('dandan');
  //   const day = event.target.dataset.day;
  //   if(day) {
  //     btns.forEach((btn)=> {
  //       btn.classList.remove('live')
  //     })
  //     event.target.classList.add('live')
  //     daycols.forEach((daycol)=> {
  //       daycol.classList.remove('live')
  //     })
  //     const element = document.getElementById(day)
  //     element.classList.add('live')
  //   }
  // }  

}