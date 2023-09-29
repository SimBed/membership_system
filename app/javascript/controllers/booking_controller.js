import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  connect() {
    const buttonContainerEl = document.querySelector(".button-container-full-width");
    const btns = document.querySelectorAll('button');
    buttonContainerEl.addEventListener('click', (event) => {
      const daycols = document.querySelectorAll('.booking-day');
      const day = event.target.dataset.day;
      if(day) {
        btns.forEach((btn)=> {
          btn.classList.remove('live')
        })
        event.target.classList.add('live')
        daycols.forEach((daycol)=> {
          daycol.classList.remove('live')
        })
        // const element = document.getElementById(day)
        // element.classList.add('live')
        const elements = document.querySelectorAll(`.booking-day${day}`);
        elements.forEach((element)=> {
          element.classList.add('live');
        })
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