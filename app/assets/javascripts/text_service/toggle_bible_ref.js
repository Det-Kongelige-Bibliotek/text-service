"use strict";

function toggle_bible_ref() {
    let text_bible_refs = document.querySelectorAll("span.symbol.Bibel");
    if (this.classList.contains('active')) {
        for (i = 0; i < text_bible_refs.length; i++) {
            text_bible_refs[i].style.display = 'none';
            text_bible_refs[i].parentElement.classList.remove ('show_icons');
        }
    } else {
        for (i = 0; i < text_bible_refs.length; i++) {
            text_bible_refs[i].style.display = 'inline-block';
            text_bible_refs[i].classList.add('icon', 'Bibel');
            text_bible_refs[i].parentElement.classList.add ('show_icons');
        }
    }
    this.classList.toggle('active');
}
let show_bible_refs = document.getElementById('Bibel');
if (show_bible_refs) {
    show_bible_refs.addEventListener('click', toggle_bible_ref, false);
}
