"use strict";

function toggle_location() {
    let text_locations = document.querySelectorAll("span.symbol.place");
    if (this.classList.contains('active')) {
        for (i = 0; i < text_locations.length; i++) {
            text_locations[i].style.display = 'none';
            text_locations[i].parentElement.classList.remove ('show_icons');
            // text_locations[i].parentElement.style.display = 'none';
        }
    } else {
        for (i = 0; i < text_locations.length; i++) {
            text_locations[i].style.display = 'inline';
            text_locations[i].classList.add('icon', 'place');
            text_locations[i].parentElement.classList.add ('show_icons');
            // text_locations[i].parentElement.style.display = 'inline';
        }
    }
    this.classList.toggle('active');
}

let show_locations = document.getElementById('place');
if (show_locations) {
    show_locations.addEventListener('click', toggle_location, false);
}
