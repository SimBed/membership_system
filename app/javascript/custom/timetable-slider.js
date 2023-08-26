const buttonContainerEl = document.querySelector(".button-container");
const btns = document.querySelectorAll('button');
const daycols = document.querySelectorAll('.tt-day');
buttonContainerEl.addEventListener('click', (event) => {
  updateDay(event);
})

function updateDay(event) {
  const day = event.target.dataset.day;
  if(day) {
    btns.forEach((btn)=> {
      btn.classList.remove('live')
    })
    event.target.classList.add('live')
    daycols.forEach((daycol)=> {
      daycol.classList.remove('live', 'd-flex', 'flex-column')
    })
    const element = document.getElementById(day)
    element.classList.add('live', 'd-flex', 'flex-column')
  }
}


// let smallScreenWindow = window.matchMedia("(max-width: 767px)");
// const swipeArea = document.querySelector('#timetable');
// if (smallScreenWindow.matches) {
//   let startX;
  
//   swipeArea.addEventListener('touchstart', handleTouchStart, false);
//   swipeArea.addEventListener('touchend', handleTouchEnd, false);
// }
// else {
//   swipeArea.removeEventListener('touchstart', handleTouchStart, false);
//   swipeArea.removeEventListener('touchend', handleTouchEnd, false);
// }


// // mm in the function arg is the matchMedia object, passed back into the function
// smallScreenWindow.addEventListener('change', function(mm) {
//   const swipeArea = document.querySelector('#timetable');
//     if (mm.matches) {
//       let startX;
      
//       swipeArea.addEventListener('touchstart', handleTouchStart, false);
//       swipeArea.addEventListener('touchend', handleTouchEnd, false);
//     }
//     else {
//       swipeArea.removeEventListener('touchstart', handleTouchStart, false);
//       swipeArea.removeEventListener('touchend', handleTouchEnd, false);
//     }
// });

// function handleTouchStart(event) {
//   const touch = event.touches[0];
//   startX = touch.clientX;
//   // console.log(startX);
// }

// function handleTouchEnd(event) {
//   const touch = event.changedTouches[0];
//   const endX = touch.clientX;
//   //  60 is a reasonable allowance to avoid swiping up being mistaken for swiping across
//   if (endX > startX + 60) {
//     nextDay();
//   } else if (endX < startX - 60) {
//     prevDay();
//   }
// }

function getNextDay(currentDay) {
  if (currentDay == daycols.length - 1) {
    return 0} else {
      return parseInt(currentDay) + 1;
  }
}
function getPrevDay(currentDay) {
  if (currentDay == 0) {
    return daycols.length - 1} else {
      return parseInt(currentDay) - 1;
  }
}

function nextDay() {
  let currentDayButton = document.querySelector('button.live');
  let currentDay = currentDayButton.dataset.day;
  let currentDayColumn = document.getElementById(currentDay);
  let nextDay = getNextDay(currentDay);
  let nextDayButton = document.querySelector(`[data-day="${nextDay}"]`);
  let nextDayColumn = document.getElementById(nextDay);
  if(currentDay) {
    currentDayButton.classList.remove('live');
    nextDayButton.classList.add('live');
    currentDayColumn.classList.remove('live', 'd-flex', 'flex-column');
    nextDayColumn.classList.add('live', 'd-flex', 'flex-column');
  }
}


function prevDay() {
  let currentDayButton = document.querySelector('button.live');
  let currentDay = currentDayButton.dataset.day;
  let currentDayColumn = document.getElementById(currentDay);
  let prevDay = getPrevDay(currentDay);
  let prevDayButton = document.querySelector(`[data-day="${prevDay}"]`);
  let prevDayColumn = document.getElementById(prevDay);
  if(currentDay) {
    currentDayButton.classList.remove('live');
    prevDayButton.classList.add('live');
    currentDayColumn.classList.remove('live', 'd-flex', 'flex-column');
    prevDayColumn.classList.add('live', 'd-flex', 'flex-column');
  }
}
