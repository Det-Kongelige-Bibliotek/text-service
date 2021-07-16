"use strict";

function toggle_person() {
    let text_persons = document.querySelectorAll("span.symbol.person");
    if (this.classList.contains('active')) {
        for (i = 0; i < text_persons.length; i++) {
            text_persons[i].style.display = 'none';
            text_persons[i].parentElement.classList.remove ('show_icons');
        }
    } else {
        for (i = 0; i < text_persons.length; i++) {
            text_persons[i].style.display = 'inline';
            text_persons[i].classList.add('icon', 'person');
            text_persons[i].parentElement.classList.add ('show_icons');
        }
    }
    this.classList.toggle('active');
}

let show_persons = document.getElementById('person');
if (show_persons) {
    show_persons.addEventListener('click', toggle_person, false);
}
