(function (exports) {
  class InfiniteRecords {
    container = document.querySelector('.infinite-scroll-container');

    WAYPOINT_SIZE = parseInt(this.container.dataset.waypointSize, 10);
    NUM_TOTAL_RECORDS = parseInt(this.container.dataset.totalRecords, 10);
    NUM_TOTAL_WAYPOINTS = Math.ceil(
      this.NUM_TOTAL_RECORDS / this.WAYPOINT_SIZE
    );

    modal = new ModalManager(document.querySelector('[data-loading-modal]'));

    showAllRecordsBtn = document.querySelector('[data-show-all-records]');

    isOkToObserve = true;

    waypointObserver = new IntersectionObserver(
      // Wrap handler in arrow fn to preserve `this` context
      (entries, observer) => {
        this.waypointScrollHandler(entries, observer);
      },
      {
        root: this.container,
        rootMargin: '0px 0px 0px 0px',
      }
    );

    currentRecordObserver = new IntersectionObserver(
      this.currentRecordScrollHandler,
      {
        root: this.container,
        rootMargin: '-5px 0px -95% 0px', // only the top sliver
      }
    );

    /**
     * @constructor
     * @param {String} resourceUri - The URI of the root resource, e.g.
     * /repositories/2/resources/1234
     * @param {String} js_path - The path to the js directory as returned
     * from Rails `javascript_path` helper
     * @returns {InfiniteRecords} - InfiniteRecords instance
     */
    constructor(resourceUri, js_path) {
      this.resourceUri = resourceUri;
      this.js_path = js_path;

      this.container.addEventListener('scrollend', () => {
        this.isOkToObserve = true;
      });

      this.showAllRecordsBtn.addEventListener('click', () => {
        this.populateAllWaypoints();
      });

      this.initRecords(window.location.hash);
    }

    /**
     * initRecords
     * @description - Append one or more waypoints to the DOM depending
     * on window.location.hash
     * @param {Location} hash - Location hash string
     */
    async initRecords(hash) {
      const initialWaypoints = [];

      if (hash === '') {
        initialWaypoints.push(0);

        if (this.NUM_TOTAL_WAYPOINTS > 1) initialWaypoints.push(1);

        this.renderWaypoints(initialWaypoints);
      } else {
        // there is a hash, so let's scroll to that record, but first we have
        // to get the waypoint numbers of the record and any of its WP neighbors
        // we get the record by parsing the hash, then we get its waypoint number.
        // then we check if there are empty neighbors before and after this waypoint.
        const recordUri = this.treeIdToRecordUri(hash);
        const recordWaypointNum = this.treeIdtoWaypointNumber(hash);

        initialWaypoints.push(recordWaypointNum);

        if (this.hasEmptyPrevWP(recordWaypointNum)) {
          initialWaypoints.push(recordWaypointNum - 1);
        }

        if (this.hasEmptyNextWP(recordWaypointNum)) {
          initialWaypoints.push(recordWaypointNum + 1);
        }

        this.renderWaypoints(initialWaypoints, recordUri);
      }
    }

    /**
     * renderWaypoints
     * @description - Render the given waypoints, watch for any empty neighbors,
     * and scroll to the given record if provided
     * @param {number[]} wpNums - array of waypoint numbers to render
     * @param {string|null} [scrollToRecordUri=null] - uri of the record
     * to scroll to after the waypoints have been rendered, default null
     * @param {boolean} [shouldOpenModal=true] - whether or not to open the
     * loading modal, default true
     * @param {boolean} [shouldCloseModal=true] - whether or not to close the
     * loading modal, default true
     */
    async renderWaypoints(
      wpNums,
      scrollToRecordUri = null,
      shouldOpenModal = true,
      shouldCloseModal = true
    ) {
      this.isOkToObserve = false;

      if (shouldOpenModal) this.modal.toggle();

      const data = await this.fetchWaypoints(wpNums);

      this.populateWaypoints(data);

      this.considerEmptyNeighbors(wpNums);

      if (scrollToRecordUri !== null) {
        const targetRecord = document.querySelector(
          `.infinite-record-record[data-uri="${scrollToRecordUri}"]`
        );

        targetRecord.scrollIntoView({ behavior: 'smooth' });
      }

      // Safari scroll bugs surface majorly when the next line is uncommented
      // if (!scrollToRecordUri) isOkToObserve = true;

      if (shouldCloseModal) this.modal.toggle();
    }

    /**
     * fetchWaypoints
     * @description Fetch one or more waypoints of records
     * @param {number[]} wpNums - array of the waypoint numbers to fetch
     * @returns {Promise} - A Promise that resolves to an array of waypoint
     * objects, each with the signature: `{ wpNum, records }`
     */
    async fetchWaypoints(wpNums) {
      console.log('wpNums:', wpNums);
      if (wpNums.length === 1) {
        return [await this.fetchWaypoint(wpNums[0])];
      } else if (wpNums.length > 1) {
        const promises = [];

        wpNums.forEach(wpNum => {
          promises.push(this.fetchWaypoint(wpNum));
        });

        return Promise.all(promises)
          .then(responses => {
            console.log('responses:', responses);
            return responses;
          })
          .catch(err => {
            console.error(err);
          });
      }
    }

    /**
     * fetchWaypoint
     * @description Fetch a waypoint of records
     * @param {number} wpNum - the waypoint number to fetch
     * @returns {Promise} - Promise that resolves with the waypoint object made up of
     * keys of record uris and values of record markup
     */
    fetchWaypoint(wpNum) {
      const waypoint = document.querySelector(
        `.waypoint[data-waypoint-number='${wpNum}']:not(.populated)`
      );
      const query = new URLSearchParams();

      waypoint.dataset.uris.split(';').forEach(uri => {
        query.append('urls[]', uri);
      });

      const url = `${this.resourceUri}/infinite/waypoints?${query}`;

      return fetch(url)
        .then(response => response.json())
        .then(records => ({ wpNum, records }))
        .catch(err => {
          console.error(err);
        });
    }

    /**
     * populateWaypoints
     * @description Append markup of records data to one or more waypoints,
     * start observing each record via `contentRecordObs`,
     * run `updateShowingCurrent()`, and clear the waypoint number(s) from any
     * record data attributes that include it
     * @param {Object[]} waypoints - array of waypoint objects as
     * returned from `fetchWaypoints()`, each of which represents one waypoint
     * with the signature: { wpNum, records}
     * @param {boolean} [updateShouldCloseModal] - whether or not the
     * updateShowingCurrent() call should close the loading modal, used by
     * populateAllWaypoints(), default false
     */
    populateWaypoints(waypoints, updateShouldCloseModal = false) {
      console.log('populateWaypoints waypoints: ', waypoints);
      waypoints.forEach(waypoint => {
        if (waypoint == undefined) {
          // Failed fetches from worker get passed as undefined
          return;
        }

        const { wpNum, records } = waypoint;
        const waypointEl = document.querySelector(
          `.waypoint[data-waypoint-number='${wpNum}']:not(.populated)`
        );

        if (!waypointEl) {
          return;
        }

        const uris = waypointEl.dataset.uris.split(';');
        const recordsFrag = new DocumentFragment();

        uris.forEach((uri, i) => {
          const recordNumber = wpNum * this.WAYPOINT_SIZE + i;
          const type = uri.split('/')[3].replace(/s+$/, '');
          const id = uri.split('/')[4];
          const treeId = `tree::${type}_${id}`;
          const recordEl = document
            .querySelector('#infinite-record-record-template')
            .content.cloneNode(true);

          recordEl.querySelector('div').id = treeId;
          recordEl.querySelector('div').setAttribute('data-uri', uri);
          recordEl.querySelector('div').setAttribute('data-observe', 'record');
          recordEl
            .querySelector('div')
            .setAttribute('data-record-number', recordNumber);

          // The record container is all set up so inject ajax data
          recordEl
            .querySelector('div')
            .insertAdjacentHTML('beforeend', records[uri]);

          recordsFrag.appendChild(recordEl);
        });

        waypointEl.appendChild(recordsFrag);

        // Watch the new records to highlight the current title in the tree
        waypointEl
          .querySelectorAll('.infinite-record-record')
          .forEach(record => {
            this.currentRecordObserver.observe(record);
          });

        waypointEl.classList.add('populated');

        this.clearWaypointFromDatasets(wpNum);

        this.updateShowingCurrent(updateShouldCloseModal);
      });
    }

    /**
     * considerEmptyNeighbors
     * @description - Conditionally set the `data-observe-for-waypoints`
     * attribute on all records in a given waypoint with an empty neighbor
     * (the values of which are a stringified array of waypoint numbers of
     * the empty neighbors), and start observing each record to populate
     * nearby empty waypoints
     * @param {number[]} wpNums - array of waypoint numbers to consider
     */
    considerEmptyNeighbors(wpNums) {
      wpNums.forEach(wpNum => {
        const waypoint = document.querySelector(
          `.waypoint.populated[data-waypoint-number='${wpNum}']`
        );

        if (!waypoint) {
          return;
        }

        const empties = [];

        if (this.hasEmptyPrevWP(wpNum)) {
          empties.push(wpNum - 1);

          // When scrolling up watch for the previous empty waypoint's
          // previous empty waypoint too to (hopefully) avoid missed
          // observations from fast scrolling (mostly in Safari)
          if (this.hasEmptyPrevWP(wpNum - 1)) {
            empties.push(wpNum - 2);
          }
        }

        if (this.hasEmptyNextWP(wpNum)) {
          empties.push(wpNum + 1);
        }

        if (empties.length > 0) {
          const records = waypoint.querySelectorAll('.infinite-record-record');

          records.forEach(record => {
            record.setAttribute(
              'data-observe-for-waypoints',
              JSON.stringify(empties)
            );

            this.waypointObserver.observe(record);
          });
        }
      });
    }

    /**
     * clearWaypointFromDatasets
     * @description - Remove a waypoint number from all record data attributes
     * that include the waypoint number; remove the records's data attribute
     * entirely if the waypoint number is the only item in the attribute's value
     */
    clearWaypointFromDatasets(wpNum) {
      const potentialRecords = document.querySelectorAll(
        `.infinite-record-record[data-observe-for-waypoints*='${wpNum}']`
      );
      const records = Array.from(potentialRecords).filter(record => {
        const wpNums = JSON.parse(record.dataset.observeForWaypoints);

        return wpNums.includes(wpNum);
      });

      records.forEach(record => {
        const wpNums = JSON.parse(record.dataset.observeForWaypoints);
        const newWpNums = wpNums.filter(num => num !== wpNum);

        if (newWpNums.length > 0) {
          record.dataset.observeForWaypoints = JSON.stringify(newWpNums);
        } else {
          record.removeAttribute('data-observe-for-waypoints');

          this.waypointObserver.unobserve(record);
        }
      });
    }

    /**
     * updateShowingCurrent
     * @description Update the number of records currently showing label
     * @param {boolean} shouldCloseModal - whether or not to close the
     * loading modal when all records are shown
     */
    updateShowingCurrent(shouldCloseModal) {
      const showingCurrentEl = document.querySelector('[data-showing-current]');
      const numPresentRecords = this.container.querySelectorAll(
        '.infinite-record-record'
      ).length;

      showingCurrentEl.classList.add('item-highlight');
      showingCurrentEl.textContent = numPresentRecords;
      showingCurrentEl.onanimationend = () => {
        showingCurrentEl.classList.remove('item-highlight');
      };

      if (numPresentRecords === this.NUM_TOTAL_RECORDS) {
        this.showAllRecordsBtn.classList.add('item-fadeout');
        this.showAllRecordsBtn.onanimationend = () => {
          this.showAllRecordsBtn.style.opacity = 0;
        };
        this.showAllRecordsBtn.setAttribute('disabled', true);

        if (shouldCloseModal) this.modal.toggle();
      }
    }

    /**
     * waypointScrollHandler
     * @description - IntersectionObserver callback for waypoint observer
     * @param {IntersectionObserverEntry[]} entries - array of entries
     * @param {IntersectionObserver} observer - the observer
     */
    waypointScrollHandler(entries, observer) {
      entries.forEach(entry => {
        if (entry.isIntersecting && this.isOkToObserve) {
          const emptyWaypointNums = entry.target.dataset.observeForWaypoints;
          const observingTargets = document.querySelectorAll(
            `[data-observe-for-waypoints="${emptyWaypointNums}"]`
          );

          this.renderWaypoints(JSON.parse(emptyWaypointNums));

          observingTargets.forEach(target => {
            target.removeAttribute('data-observe-for-waypoints');

            observer.unobserve(target);
          });
        }
      });
    }

    /**
     * populateAllWaypoints
     * @description Populate the remaining empty waypoints
     * @param {boolean} [shouldImmediatelyToggleModal = true] - Whether or not
     * the modal should be toggled when called, default is true
     */
    populateAllWaypoints(shouldImmediatelyToggleModal = true) {
      if (shouldImmediatelyToggleModal) this.modal.toggle();

      this.waypointObserver.disconnect();

      const MAX_WAYPOINTS_MAIN_THREAD = 20;
      const waypointNums = Array.from(
        this.container.querySelectorAll('.waypoint:not(.populated)')
      ).map(waypoint => parseInt(waypoint.dataset.waypointNumber, 10));

      this.container.removeEventListener('scrollend', () => {
        this.isOkToObserve = true;
      });

      if (
        waypointNums.length > 0 &&
        waypointNums.length < MAX_WAYPOINTS_MAIN_THREAD
      ) {
        this.renderWaypoints(waypointNums, null, false);
      } else {
        const worker = new Worker(`${this.js_path}worker_infinite.js`);
        const waypointTuples = waypointNums.map(wpNum => [
          wpNum,
          this.container
            .querySelector(`.waypoint[data-waypoint-number='${wpNum}']`)
            .dataset.uris.split(';'),
        ]);

        worker.postMessage({
          waypointTuples,
          resourceUri: this.resourceUri,
        });

        worker.onmessage = e => {
          if (e.data.data) {
            this.populateWaypoints(e.data.data, true);
          } else if (e.data.done) {
            const numPresentRecords = this.container.querySelectorAll(
              '.infinite-record-record'
            ).length;

            if (numPresentRecords < this.NUM_TOTAL_RECORDS) {
              // Some records still missing (network fail?) so recurse
              this.populateAllWaypoints(this.modal.isOpen ? false : true);
            }
          }
        };
      }
    }

    /**
     * currentRecordScrollHandler
     * @description - IntersectionObserver callback for current record observer
     * @param {IntersectionObserverEntry[]} entries - array of entries
     */
    currentRecordScrollHandler(entries) {
      // NEEDS TWEAKING TO AVOID THE CONSOLE ERROR MESSAGES
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const uri = entry.target.dataset.uri;
          const _new = document.querySelector(
            `#tree-container .table-row[data-uri="${uri}"]`
          );
          const old = document.querySelector(
            '#tree-container .table-row.current'
          );

          if (old) {
            old.classList.remove('current');
          }

          _new.classList.add('current');
        }
      });
    }

    /**
     * treeLinkHandler
     * @description - Handle click events on record titles in the tree by
     * scrolling to the record if it exists, or rendering the record's
     * waypoint and nearby waypoints then scrolling to the record
     * @param {Event} event - click event
     */
    async treeLinkHandler(event) {
      event.preventDefault();

      const targetDivId = event.target.href.split('#')[1];
      const recordUri = this.treeIdToRecordUri(targetDivId);

      const recordSelector = `.infinite-record-record[data-uri='${recordUri}']`;
      const scrollOpts = { behavior: 'smooth' };

      window.location.hash = targetDivId;

      const record = this.container.querySelector(recordSelector);

      if (record) {
        record.scrollIntoView(scrollOpts);
      } else {
        // Record doesn't exist so render its waypoint and any
        // empty neighbors, then scroll to the record
        const recordWaypointNum = this.treeIdtoWaypointNumber(targetDivId);
        const newWaypoints = [recordWaypointNum];

        if (this.hasEmptyPrevWP(recordWaypointNum)) {
          newWaypoints.push(recordWaypointNum - 1);
        }

        if (this.hasEmptyNextWP(recordWaypointNum)) {
          newWaypoints.push(recordWaypointNum + 1);
        }

        this.renderWaypoints(newWaypoints, recordUri);
      }
    }

    /**
     * treeIdToRecordUri
     * @description Get the uri of a record given the treeId; useful since querying the DOM
     * for a string with `::` is messy.
     * @param {string} treeId - treeId of the record with or without a leading '#'
     * eg: #tree::archival_object_123
     * @returns {string} - record uri, e.g. /repositories/2/archival_objects/123
     */
    treeIdToRecordUri(treeId) {
      const repoId = this.resourceUri.split('/')[2];
      const type = treeId.includes('resource')
        ? 'resources'
        : 'archival_objects';
      const id = treeId.split('_')[treeId.split('_').length - 1];

      return `/repositories/${repoId}/${type}/${id}`;
    }

    /**
     * treeIdtoWaypointNumber
     * @description Get the waypoint number of the record with the given treeId
     * @param {string} treeId - treeId of the record with or without a leading '#'
     * eg: #tree::archival_object_123
     * @returns {number} - waypoint number
     */
    treeIdtoWaypointNumber(treeId) {
      return parseInt(
        this.container
          .querySelector(
            `.waypoint[data-uris*='${this.treeIdToRecordUri(treeId)}']`
          )
          .getAttribute('data-waypoint-number'),
        10
      );
    }

    /**
     * hasEmptyPrevWP
     * @description Determine if the waypoint before the given waypoint is empty
     * @param {number} wpNum - number of the waypoint with possible empty neighbor
     * @returns {boolean} - true if the waypoint before the given waypoint is empty
     */
    hasEmptyPrevWP(wpNum) {
      return wpNum > 0
        ? !this.container
            .querySelector(`.waypoint[data-waypoint-number='${wpNum - 1}']`)
            .classList.contains('populated')
        : false;
    }

    /**
     * hasEmptyNextWP
     * @description Determine if the waypoint after the given waypoint is empty
     * @param {number} wpNum - number of the waypoint with possible empty neighbor
     * @returns {boolean} - true if the waypoint after the given waypoint is empty
     */
    hasEmptyNextWP(wpNum) {
      return wpNum <= this.NUM_TOTAL_WAYPOINTS - 2
        ? !this.container
            .querySelector(`.waypoint[data-waypoint-number='${wpNum + 1}']`)
            .classList.contains('populated')
        : false;
    }
  }

  exports.InfiniteRecords = InfiniteRecords;
})(window);
