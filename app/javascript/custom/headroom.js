let startY = window.scrollY;
document.addEventListener('scroll', () => {
  let navbarEl = document.querySelector('.navbar');
  if (window.scrollY > startY) {
    navbarEl.classList.add('disappear');
  } else {
    navbarEl.classList.remove('disappear');
  }
  startY = window.scrollY;
})
