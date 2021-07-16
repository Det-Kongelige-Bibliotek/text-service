"use strict";

function toggle_text_comments() {
    let text_comments = document.querySelectorAll("span.symbol.comment");
    if (this.classList.contains('active')) {
        for (i = 0; i < text_comments.length; i++) {
            text_comments[i].style.display = 'none';
            text_comments[i].parentElement.classList.remove ('show_icons');
        }
    } else {
        for (i = 0; i < text_comments.length; i++) {
            text_comments[i].style.display = 'inline';
            text_comments[i].classList.add('icon', 'comment');
            text_comments[i].parentElement.classList.add ('show_icons');
        }
    }
    this.classList.toggle('active');
}

let show_comments = document.getElementById('comment');
if (show_comments) {
    show_comments.addEventListener('click', toggle_text_comments, false);
}
