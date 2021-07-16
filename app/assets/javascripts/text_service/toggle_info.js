"use strict";

function toggle_infos() {
    let text_infos = document.querySelectorAll("span.symbol.info");
    if (this.classList.contains('active')) {
        for (i = 0; i < text_infos.length; i++) {
            text_infos[i].style.display = 'none';
            text_infos[i].parentElement.classList.remove ('show_icons');
        }
    } else {
        for (i = 0; i < text_infos.length; i++) {
            text_infos[i].style.display = 'inline';
            text_infos[i].classList.add('icon', 'info');
            text_infos[i].parentElement.classList.add ('show_icons');
        }
    }
    this.classList.toggle('active');
}

let show_infos = document.getElementById('info');
if (show_infos) {
    show_infos.addEventListener('click', toggle_infos, false);
}
