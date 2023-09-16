const buttonContainerEl = document.querySelector(".button-container-full-width");
const btns = document.querySelectorAll('button');
const daycols = document.querySelectorAll('.booking-day');
buttonContainerEl.addEventListener('click', (event) => {
  updateDay(event);
})

function updateDay(event) {
  console.log('dan');
  const day = event.target.dataset.day;
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
}