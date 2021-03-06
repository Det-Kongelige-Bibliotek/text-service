/* global $,window, jQuery, dkBreve, KbOSD */
"use strict";
window.dkBreve = (function (window, $, undefined) {
    'use strict';
    var DkBreve = function () {
    };

    DkBreve.prototype = {

        has_text: function () {
            var ocrElem = $('.ocr');
            if (ocrElem[0]) {
                return true;
            } else {
                return false;
            }
        },
        /**
         * Get current page in ocr pane
         */
        getOcrCurrentPage: function () {
            var ocrElem = $('.ocr'),
                ocrScrollTop = 50 + 5,
                ocrScrollTopOffset = $(window).scrollTop(),
                ocrBreaks = $('.pageBreak');
            var i = 0;
            if (ocrBreaks.length) {
                if ($(ocrBreaks[0]).offset().top - ocrScrollTopOffset > ocrScrollTop) {
                    return 1; // user are before the very first pageBreak => page 1
                }
                while (i < ocrBreaks.length && $(ocrBreaks[i]).offset().top - ocrScrollTopOffset <= ocrScrollTop) {
                    i++;
                }
                return i + 1;
            }
        },

        /**
         * Scroll to a (one-based) numbered page in the ocr
         * @param page
         */
        gotoOcrPage: function (page, skipAnimation) {
            var that = this,
                citationPageNumber = document.getElementById('pageNumber'),
                pageCount = $('.pageBreak').length + 1;
            if (citationPageNumber != null) {
                if (page > 1) {
                    citationPageNumber.innerText = ($('.ocr .pageBreak a small')[page - 2]).textContent;
                } else {
                    citationPageNumber.innerText = first_page;// first_page is a global variable defined in the text.html view containing page_ssi from solr
                }
            }
            if (page < 1 || page > pageCount) {
                throw('DkBreve.gotoOcrPage: page "' + page + '" out of bounds.');
            }
            if (that.animInProgress) {
                $([document.documentElement, document.body]).stop(true, true);
            }
            if (skipAnimation) {
                that.animInProgress = true;
                if (page === 1) {
                    $([document.documentElement, document.body]).scrollTop = 0;
                } else {
                    $([document.documentElement, document.body]).scrollTop = $($('.pageBreak')[page - 2]).position().top - 50;
                }
                setTimeout(function () {
                    that.animInProgress = false;
                }, 0);
            } else {
                that.animInProgress = true;
                if (page === 1) {
                    $([document.documentElement, document.body]).animate({
                        scrollTop: 0
                    }, 500, 'swing', function () {
                        that.animInProgress = false;
                    }); // scroll to top of text
                } else {
                    $([document.documentElement, document.body]).animate({
                        scrollTop: $($('.pageBreak')[page - 2]).offset().top - 50
                    }, 500, 'swing', function () {
                        that.animInProgress = false;
                    });
                }
            }
        },
        onOcrScroll: function () {
            var that = dkBreve;
            if (that.has_text()) {
                if (!that.animInProgress) {
                    // this is a genuine scroll event, not something that origins from a kbOSD event
                    var currentOcrPage = that.getOcrCurrentPage(),
                        citationPageNumber = document.getElementById('pageNumber'),
                        hashTagInURI = document.getElementById('hashTagInURI'),
                        kbosd = KbOSD.prototype.instances[0]; // The dkBreve object should have a kbosd property set to the KbOSD it uses!
                    if (citationPageNumber != null) {
                        if (currentOcrPage > 1 && hashTagInURI != null) {
                            citationPageNumber.innerText = ($('.ocr .pageBreak a small')[currentOcrPage - 2]).textContent;
                            hashTagInURI.innerText = "#" + ($('.ocr .pageBreak')[currentOcrPage - 2]).id;
                        } else {
                            citationPageNumber.innerText = first_page;// first_page is a global variable defined in the text.html view containing page_ssi from solr
                            hashTagInURI.innerText = "";
                        }
                    }
                    if (kbosd.getCurrentPage() !== currentOcrPage) {
                        that.scrollingInProgress = true;
                        kbosd.setCurrentPage(currentOcrPage, function () {
                            that.scrollingInProgress = false; // This is ALMOST enough ... but it
                        });
                    }
                }
            }
        },
        onFullScreen: function (e) {
            var that = dkBreve, // TODO: This is so cheating, but I only get the contentElement as scope. :-/
                fullScreen = e.detail.fullScreen;
            that.fullScreen = fullScreen;
            if (!fullScreen) {
                // just returned from fullscreen - scroll ocr pane accordingly
                that.gotoOcrPage(that.kbosd.getCurrentPage(), true);
            }
        },
        onDocumentReady: function () {

            var headerFooterHeight = dkBreve.getFooterAndHeaderHeight(),
                windowHeight = $(window).innerHeight(),
                contentHeight = windowHeight - headerFooterHeight - 10;
            dkBreve.setContentHeight(contentHeight);


            $(window).resize(function () {
                dkBreve.onWindowResize.call(dkBreve);
            });
        },
        onKbOSDReady: function (kbosd) {
            var that = this;
            that.kbosd = kbosd;
            if ((kbosd.pageCount > 1) && (that.has_text())) { // if there isn't more than one page, no synchronization between the panes are needed.
                //currentOcrpage is more than 1 if readed by the URL
                var currentOcrPage = that.getOcrCurrentPage();
                if (currentOcrPage > 1) {
                    kbosd = KbOSD.prototype.instances[0]; // The dkBreve object should have a kbosd property set to the KbOSD it uses!
                    if (kbosd.getCurrentPage() !== currentOcrPage) {
                        that.scrollingInProgress = true;
                        kbosd.setCurrentPage(currentOcrPage, function () {
                            that.scrollingInProgress = false; // This is ALMOST enough ... but it
                        });
                    }
                } else { // initlaize from osd gragon page instead
                    that.gotoOcrPage(kbosd.getCurrentPage(), true);
                }

                $(kbosd.contentElem).on('pagechange', function (e) {
                    if (!that.scrollingInProgress && !that.fullScreen) {
                        that.gotoOcrPage(e.detail.page);
                    }
                });
                $(kbosd.contentElem).on('fullScreen', that.onFullScreen);
                $(window).scroll(this.onOcrScroll);
            }
        },
        onWindowResize: function () {
            this.setContentHeight($(window).innerHeight() - this.getFooterAndHeaderHeight());
        },
        getFooterAndHeaderHeight: function () {
            return $('.page_links').outerHeight() +
                $('.workNavBar').outerHeight() +
                $('h1[itemprop=name]').outerHeight() +
                $('.search-widgets').outerHeight() + // FIXME: According to me this shouldn't be necessary, since these are pulled right and thereby out of the flow, but I can observe that the end result lacks approx 32 px.? /HAFE
                $('#user-util-collapse').outerHeight() +
                $('footer.pageFooter').outerHeight();
        },
        setContentHeight: function (height) {
            if (height > 200) {
                $('.contentContainer').css('maxHeight', height);
                $('.textAndFacsimileContainer').css('minHeight', height);
            }
        }
    };

    return new DkBreve();
})(window, jQuery);

$(document).on('kbosdready', function (e) {
    dkBreve.onKbOSDReady(e.detail.kbosd);
});


//////////////////////////////////////////////////////
$(document).ready(function () {
    window.addEventListener("scroll", function () {
        //
        let doc = document.documentElement;
        let top = (window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);
        let lpContainer = $('.lpContainer');
        if (lpContainer.length){
            if (lpContainer.position().top <= top) {
                $('#scrollTop').css("visibility", "visible"); // Show the scrollTop button when it is after page 2
                // The element is visible, do something
            } else {
                $('#scrollTop').css("visibility", "hidden");// Hide the scrollTop button when it is already at top
                // The element is NOT visible, do something else
            }
        }
// If there is no OSD in the page so there is no pagination
// The following code checks if there is no pagination then 'on scroll' changes the page number on citation
        if (typeof (has_facs) !== 'undefined') {
            if (!(has_facs)) {
                let currentOcrPage = getOcrCurrentPage();
                let citationPageNumber = document.getElementById('pageNumber');
                let hashTagInURI = document.getElementById('hashTagInURI');
                if (citationPageNumber) {
                    if (currentOcrPage > 1) {
                        citationPageNumber.innerText = ($('.ocr .pageBreak a small')[currentOcrPage - 2]).textContent;
                        hashTagInURI.innerText = "#" + ($('.ocr .pageBreak')[currentOcrPage - 2]).id;
                    } else {
                        citationPageNumber.innerText = first_page;// first_page is a global variable defined in the text.html view containing page_ssi from solr
                        hashTagInURI.innerText = ""
                    }
                }

                function getOcrCurrentPage() {
                    var ocrElem = $('.ocr'),
                        ocrScrollTop = ocrElem[0].scrollTop,
                        ocrScrollTopOffset = ocrScrollTop + 9, // Magic number 9 is 1 px less than the margin added when setting pages
                        ocrBreaks = $('.pageBreak', ocrElem);
                    var i = 0;
                    if ($(ocrBreaks).length) {
                        if ($(ocrBreaks[0]).position().top + ocrScrollTopOffset > ocrScrollTop) {
                            return 1; // user are before the very first pageBreak => page 1
                        }
                        while (i < ocrBreaks.length && $(ocrBreaks[i]).position().top + ocrScrollTopOffset <= ocrScrollTop) {
                            i++;
                        }
                    }
                    return i + 1;
                }
            }
        }
    });
});