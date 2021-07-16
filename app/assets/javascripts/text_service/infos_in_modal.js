"use strict";
var infos = document.querySelectorAll('a.info[title="Tekstkritik"]');

for (var i = 0; i < infos.length; i++) {
    var info = infos[i];
    info.dataset.toggle = "modal";
    info.dataset.target = "#info_modal";

    info.addEventListener("click", function (event) {
        event.preventDefault();
        let modal = document.getElementById('info_modal');
        let modal_body = modal.getElementsByClassName('modal-body')[0];
	    let text_critic = event.target.parentElement.parentElement.getElementsByClassName('apparatus-criticus')[0];
        modal_body.innerHTML = text_critic.innerHTML;
        text_critic.setAttribute("style", "display: none !important");
        let witnesses = text_critic.querySelectorAll('.witness[title]');
        let modal_footer = modal.getElementsByClassName('modal-footer')[0];
        modal_footer.innerHTML = '<div style="flex: 0 0 100%;"><b>]</b>: Lemmasymbol</div>';
        for (var i = 0; i < witnesses.length; i++) {
            modal_footer.innerHTML += '<div style="flex: 0 0 100%;"><b>' + witnesses[i].innerHTML + '</b>: ' + witnesses[i].getAttribute('title')+'</div>';
        }

    });
}
