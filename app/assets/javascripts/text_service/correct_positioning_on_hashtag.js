function correct_positioning_on_hashtag() {
    if (document.location.hash) {
        setTimeout(function () {
            let toolbarHeight = 60;
            let hash = document.location.hash;
            let anchor = document.getElementById(hash.substring(1));
            let topPos = anchor.offsetTop;
            window.scroll(0, findPos(anchor) - toolbarHeight);
        }, 0);
    }
}

//Finds y value of given object
function findPos(obj) {
    let curtop = 0;
    if (obj.offsetParent) {
        do {
            curtop += obj.offsetTop;
        } while (obj = obj.offsetParent);
        return [curtop];
    }
}

window.addEventListener('load', correct_positioning_on_hashtag, false)
window.addEventListener('hashchange', correct_positioning_on_hashtag, false)
