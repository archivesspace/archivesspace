(function(exports) {

    var BATCH_SIZE = 2;
    var SCROLL_DELAY_MS = 50;
    var SCROLL_DRAG_DELAY_MS = 500;
    var LOAD_THRESHOLD_PX = 5000;

    function InfiniteScroll(base_url, elt, recordCount, loaded_callback) {
        this.base_url = base_url;
        this.wrapper = elt;
        this.elt = elt.find('.infinite-record-container');
        this.recordCount = recordCount;

        this.scrollPosition = 0;
        this.scrollbarElt = undefined;

        this.scrollCallbacks = [];

        this.initScrollbar();
        this.initEventHandlers();
        this.considerPopulatingWaypoints(false, null, loaded_callback);

        this.globalStyles = $('<style />');

        $('head').append(this.globalStyles);
    }

    var scrollTimer = undefined;

    InfiniteScroll.prototype.function getLineHeight(element){
        var temp, height;
        temp = document.createElement(element.nodeName);
        temp.setAttribute("style","margin:0px;padding:0px;font-family:"+element.style.fontFamily+";font-size:"+element.style.fontSize);
        temp.innerHTML = "test";
        temp = element.parentNode.appendChild(temp);
        height = temp.clientHeight;
        temp.parentNode.removeChild(temp);
        return height;
    }

    InfiniteScroll.prototype.scrollBy = function (px) {
        var self = this;

        var containerTop = self.wrapper.offset().top;

        if (px > 0 && (self.elt.find('.waypoint:last')[0].getBoundingClientRect().bottom - containerTop) < self.wrapper.height()) {
            /* If the bottom of the last waypoint would be scrolling off the
               screen, scroll no further! */
            return;
        }

        self.scrollPosition -= px;

        if (self.scrollPosition > 0) {
            self.scrollPosition = 0;
        }

        self.elt[0].style.transform = 'translateY(' + self.scrollPosition + 'px' + ')';

        $.each(self.scrollCallbacks, function(_, callback) {
            callback();
        });

        if (scrollTimer) {
            clearInterval(scrollTimer);
        }

        scrollTimer = setTimeout(function () {
            self.considerPopulatingWaypoints(true);
            self.updateScrollPosition();
        }, SCROLL_DELAY_MS);
    };

    InfiniteScroll.prototype.initEventHandlers = function () {
        var self = this;

        var PGUP = 33;
        var PGDN = 34;
        var SPC = 32;

        var DOWN = 40;
        var UP = 38;

        $(document).on('keydown', function (e) {
            var viewportHeight = self.wrapper.height();

            if (e.keyCode == PGDN || (e.keyCode == SPC && !e.shiftKey)) {
                self.scrollBy(viewportHeight);
                e.preventDefault();
            } else if (e.keyCode == PGUP || (e.keyCode == SPC && e.shiftKey)) {
                self.scrollBy(0 - viewportHeight);
                e.preventDefault();
            } else if (e.keyCode == DOWN) {
                self.scrollBy(15);
                e.preventDefault();
            } else if (e.keyCode == UP) {
                self.scrollBy(-15);
                e.preventDefault();
            }
        });

        $(document).on('wheel', function (e) {
            if ($(e.target).closest('.infinite-record-wrapper').length == 0) {
                return true;
            }

            e.preventDefault();

            var scrollAmount = e.originalEvent.deltaY;

            /* In pixel mode deltaY can be used directly, but in line and page mode,
               multiply to get pixel values. */
            if (e.originalEvent.deltaMode == WheelEvent.DOM_DELTA_LINE) {
              scrollAmount = (scrollAmount * self.getLineHeight(self.wrapper.get(0)));
            } else if (e.originalEvent.deltaMode == WheelEvent.DOM_DELTA_PAGE) {
                scrollAmount = (scrollAmount < 0 ? -1 : 1) * self.wrapper.height();
            }

            self.scrollBy(scrollAmount);
        });
    };

    InfiniteScroll.prototype.initScrollbar = function () {
        var self = this;

        self.scrollbarElt = $('<div class="infinite-record-scrollbar" />');
        self.scrollbarElt.append($('<div class="infinite-record-spacer" />').height(10000000));
        self.scrollbarElt.height(self.wrapper.height());


        self.scrollbarElt.css('top', self.wrapper.offset().top);
        self.scrollbarElt.css('left', self.wrapper.offset().left + self.wrapper.width() + 5);

        self.scrollbarElt.scrollTop(0);

        self.scrollbarElt.on('scroll', function (e) {
            if (self.updatingScrollbar) {
                /* We generated this event by positioning the scrollbar.  Ignore it */
                self.updatingScrollbar = false;
                return;
            }

            $.each(self.scrollCallbacks, function(_, callback) {
                callback();
            });

            if (self.scrollDragDelayTimer) {
                clearInterval(self.scrollDragDelayTimer);
            }

            self.scrollDragDelayTimer = setTimeout(function () {
                var targetRecord = Math.floor((self.scrollbarElt.scrollTop() / self.scrollbarElt.find('.infinite-record-spacer').height()) * self.recordCount);
                self.scrollToRecord(targetRecord);
            }, SCROLL_DRAG_DELAY_MS);
        });

        $('body').append(self.scrollbarElt);

    };

    InfiniteScroll.prototype.registerScrollCallback = function(callback) {
        this.scrollCallbacks.push(callback);
    };

    InfiniteScroll.prototype.updateScrollPosition = function () {
        var self = this;

        var allRecords = self.elt.find('.infinite-record-record');
        var idx = self.findClosestElement(allRecords);
        var recordNumber = $(allRecords[idx]).data('record-number');

        var pxOffset = (recordNumber / self.recordCount) * $('.infinite-record-spacer').height();

        self.updatingScrollbar = true;
        self.scrollbarElt.scrollTop(pxOffset);
    };

    InfiniteScroll.prototype.scrollToRecord = function (recordNumber) {
        var self = this;

        var containerTop = self.wrapper.offset().top;

        var waypointSize = $('.waypoint').first().data('waypoint-size');
        var targetWaypoint = Math.floor(recordNumber / waypointSize);

        var scrollTo = function (recordNumber) {
            var eltTop = $('#record-number-' + recordNumber)[0].getBoundingClientRect().top;
            self.scrollPosition -= (eltTop - containerTop);
            self.elt[0].style.transform = 'translateY(' + self.scrollPosition + 'px' + ')';

            self.considerPopulatingWaypoints(true, false, function () {
                $.each(self.scrollCallbacks, function(_, callback) {
                    callback();
                });
            });
        };

        if (!$($('.waypoint')[targetWaypoint]).is('.populated')) {
            self.populateWaypoints($($('.waypoint')[targetWaypoint]), false, function () {
                scrollTo(recordNumber);
            })
        } else {
            scrollTo(recordNumber);
        }
    };


    InfiniteScroll.prototype.findClosestElement = function (elements) {
        var self = this;

        if (elements.length <= 1) {
            return 0;
        }

        var containerTop = self.wrapper.offset().top;
        var closestTop = elements.first().offset().top - containerTop;

        var startSearch = 0;
        var endSearch = elements.length - 1;

        var topOf = function (elt) {
            return elt.getBoundingClientRect().top - containerTop;
        }

        if (topOf(elements[startSearch]) <= 0 && topOf(elements[endSearch]) <= 0) {
            /* We're at the end */
            return endSearch;
        }

        while ((startSearch + 1) < endSearch && topOf(elements[startSearch]) < 0 && topOf(elements[endSearch]) > 0) {
            var midIdx = Math.floor(((endSearch - startSearch) / 2)) + startSearch;

            var midElement = elements[midIdx]
            var midElementTop = topOf(midElement);

            if (midElementTop > 0) {
                endSearch = midIdx;
            } else if (midElementTop <= 0) {
                startSearch = midIdx;
            }
        }

        if (Math.abs(topOf(elements[startSearch])) < Math.abs(topOf(elements[endSearch]))) {
            return startSearch;
        } else {
            return endSearch;
        }
    };

    var populateRunning = false;

    InfiniteScroll.prototype.considerPopulatingWaypoints = function (preserveScroll, reentrant, done_callback) {
        var self = this;

        if (!done_callback) {
            done_callback = $.noop;
        }

        if (populateRunning && !reentrant) {
            return;
        }

        populateRunning = true;

        var waypoints = self.elt.find('.waypoint:not(.populated)');
        var closestIdx = self.findClosestElement(waypoints);
        var containerTop = self.wrapper.offset().top;

        if (waypoints.length > 0 && Math.abs(waypoints[closestIdx].getBoundingClientRect().top - containerTop) < LOAD_THRESHOLD_PX) {
            var start = Math.max(closestIdx - (BATCH_SIZE / 2), 0);
            var end = start + BATCH_SIZE;

            self.populateWaypoints(waypoints.slice(start, end), preserveScroll, function () {
                self.considerPopulatingWaypoints(preserveScroll, true, done_callback);
            });
        } else {
            done_callback();
            populateRunning = false;
        }
    };

    InfiniteScroll.prototype.populateWaypoints = function (waypointElts, preserveScroll, done_callback) {
        var self = this;

        if (!done_callback) {
            done_callback = $.noop
        }

        waypointElts.addClass('populated');
        var populated_count = 0;

        $(waypointElts).each(function (_, waypoint) {
            var waypointNumber = $(waypoint).data('waypoint-number');
            var waypointSize = $(waypoint).data('waypoint-size');
            var uris = $(waypoint).data('uris').split(';');

            $.ajax(self.url_for('waypoints'), {
                method: 'GET',
                data: {
                    urls: uris,
                }
            }).done(function (records) {
                var allRecords = self.elt.find('.infinite-record-record');
                var closestRecord = undefined;
                var oldPosition = undefined;
                var newPosition = undefined;

                if (allRecords.length > 0) {
                    closestRecord = allRecords[self.findClosestElement(allRecords)];
                }

                if (closestRecord) {
                    oldPosition = closestRecord.getBoundingClientRect();
                }

                $(uris).each(function (i, uri) {
                    if (records[uri]) {
                        recordNumber = (waypointNumber * waypointSize) + i;
                        $(waypoint).append($('<div class="infinite-record-record" />').
                                    attr('id', 'record-number-' + recordNumber).
                                    data('record-number', recordNumber).
                                    data('uri', uri).
                                    html(records[uri]));
                    }
                });

                if (preserveScroll && closestRecord) {
                    newPosition = closestRecord.getBoundingClientRect();

                    self.scrollPosition += (oldPosition.top - newPosition.top);
                    self.elt[0].style.transform = 'translateY(' + self.scrollPosition + 'px' + ')';
                }

                populated_count += 1;

                if (waypointElts.length <= populated_count) {
                    done_callback();
                }
            });
        });
    };

    InfiniteScroll.prototype.url_for = function (action) {
        var self = this;

        return self.base_url + '/' + action;
    };


    InfiniteScroll.prototype.getClosestElement = function() {
        var allRecords = this.elt.find('.infinite-record-record');
        var index = this.findClosestElement(allRecords);
        return $(allRecords.get(index));
    };

    exports.InfiniteScroll = InfiniteScroll;

}(window));
