document.addEventListener('focusin', (event) => {
    if (event.target.classList.contains('nav-link')) {
        event.target.classList.add('tabbed');
    }
    if (event.target.classList.contains('dropdown-item')) {
        document.querySelector('[aria-labelledby="navbarDropdown-1"]').classList.add('show_dropdown');
        event.target.classList.add('tabbed');
    }
});

document.addEventListener('focusout', (event) => {
    if (event.target.classList.contains('nav-link')) {
        event.target.classList.remove('tabbed');
    }
    if (event.target.classList.contains('dropdown-item')) {
        document.querySelector('[aria-labelledby="navbarDropdown-1"]').classList.remove('show_dropdown');
        event.target.classList.remove('tabbed');
    }        
});