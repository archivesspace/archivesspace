(function (exports) {
  class InfiniteRecords {
    /**
     * @constructor
     * @param {string} resourceUri - The URI of the root resource, e.g.
     * /repositories/2/resources/1234
     * @param {string} appUrlPrefix - The proper app prefix
     * @param {string} workerPath - The path to the web worker for
     * `populateAllWaypoints()`
     * @param {number} mainMaxFetches - The main thread's max number of concurrent fetches
     * @param {number} workerMaxFetches - The worker's max number of concurrent fetches
     * @returns {InfiniteRecords} - InfiniteRecords instance
     */
    constructor(
      resourceUri,
      appUrlPrefix,
      workerPath,
      mainMaxFetches,
      workerMaxFetches
    ) {
      this.pageHash = window.location.hash;
      this.container = document.querySelector('#infinite-records-container');

      this.WAYPOINT_SIZE = parseInt(this.container.dataset.waypointSize, 10);
      this.NUM_TOTAL_RECORDS = parseInt(
        this.container.dataset.totalRecords,
        10
      );
      this.NUM_TOTAL_WAYPOINTS = Math.ceil(
        this.NUM_TOTAL_RECORDS / this.WAYPOINT_SIZE
      );

      this.resourceUri = resourceUri;
      this.appUrlPrefix = appUrlPrefix;
      this.workerPath = workerPath;
      this.MAIN_MAX_CONCURRENT_FETCHES = mainMaxFetches;
      this.WORKER_MAX_CONCURRENT_FETCHES = workerMaxFetches;

      this.wpQueue = [];
      this.wpQueueIsEmpty = () => this.wpQueue.length === 0;
      this.isOkToObserve = true; // used to prevent jank via programmatic scrolling

      this.modal = new ModalManager(
        document.querySelector('#records-loading-dialog')
      );

      this.waypointObserver = new IntersectionObserver(
        (entries, observer) => {
          this.waypointScrollHandler(entries, observer);
        },
        {
          root: this.container,
          rootMargin: '0px 0px 0px 0px',
        }
      );

      this.currentRecordObserver = new IntersectionObserver(
        this.currentRecordScrollHandler,
        {
          root: this.container,
          rootMargin: '-5px 0px -95% 0px', // only the top sliver
        }
      );

      this.container.addEventListener('scrollend', () => {
        this.isOkToObserve = true;
      });

      if (this.shouldShowLoadAll()) this.initLoadAll();

      this.initRecords();
    }

    /**
     * Determine whether or not to show the Load All markup given that initRecords()
     * will render up to 2 waypoints if no hash and up to 3 if hash and the hash's
     * waypoint has 2 empty neighbors
     * @returns {boolean} - True if Load All should be shown
     */
    shouldShowLoadAll() {
      if (this.pageHash === '') {
        return this.NUM_TOTAL_WAYPOINTS > 2;
      } else {
        if (this.NUM_TOTAL_WAYPOINTS > 3) return true;

        if (
          this.NUM_TOTAL_WAYPOINTS === 3 &&
          (!this.hasEmptyPrevWP(this.treeIdToWaypointNumber(this.pageHash)) ||
            !this.hasEmptyNextWP(this.treeIdToWaypointNumber(this.pageHash)))
        )
          return true;

        return false;
      }
    }

    /**
     * Render the Load All template above this.container, listen for events
     */
    initLoadAll() {
      const loadAllFrag = document
        .querySelector('#load-all-template')
        .content.cloneNode(true);

      const containerParent = this.container.parentElement;

      containerParent.parentElement.insertBefore(loadAllFrag, containerParent);

      this.loadAllSection = document.querySelector('#load-all-section');

      const loadAllInput = document.querySelector('#load-all-state');

      loadAllInput.addEventListener('input', () => {
        if (loadAllInput.checked) {
          loadAllInput.disabled = true;

          this.populateAllWaypoints();
        }
      });

      loadAllInput.addEventListener('focus', () => {
        loadAllInput.parentElement.classList.add('outline');
      });

      loadAllInput.addEventListener('blur', () => {
        loadAllInput.parentElement.classList.remove('outline');
      });
    }

    /**
     * Render the initial 1, 2, or 3 waypoints according to window.location.hash
     */
    async initRecords() {
      const initialWaypoints = [];

      if (this.pageHash === '') {
        initialWaypoints.push(0);

        if (this.NUM_TOTAL_WAYPOINTS > 1) initialWaypoints.push(1);

        this.renderWaypoints(initialWaypoints);
      } else {
        const recordUri = this.treeIdToRecordUri(this.pageHash);
        const recordWaypointNum = this.treeIdToWaypointNumber(this.pageHash);

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
     * Render the given waypoints, watch for any empty neighbors, and
     * conditionally scroll to a given record and handle the modal
     * @param {number[]} wpNums - Array of waypoint numbers to render
     * @param {string|null} [scrollToRecordUri=null] - URI of the record
     * to scroll to after the waypoints have been rendered, default null
     * @param {boolean} [shouldOpenModal=true] - Whether or not to open the
     * loading modal, default true
     * @param {boolean} [shouldCloseModal=true] - Whether or not to close the
     * loading modal, default true
     */
    async renderWaypoints(
      wpNums,
      scrollToRecordUri = null,
      shouldOpenModal = true,
      shouldCloseModal = true
    ) {
      if (shouldOpenModal) this.modal.toggle();

      const data = await this.fetchWaypoints(wpNums);

      this.populateWaypoints(data);

      this.considerEmptyNeighbors(wpNums);

      if (scrollToRecordUri !== null) {
        const targetRecord = document.querySelector(
          `.infinite-record-record[data-uri="${scrollToRecordUri}"]`
        );

        this.isOkToObserve = false;

        targetRecord.scrollIntoView({ behavior: 'smooth' });
      }

      if (shouldCloseModal) this.modal.toggle();
    }

    /**
     * Fetch one or more waypoints of records
     * @param {number[]} wpNums - Array of the waypoint numbers to fetch
     * @returns {array} - Array of waypoint objects as returned from
     * `fetchWaypoint()`, each with the signature `{ wpNum, records }`
     */
    async fetchWaypoints(wpNums) {
      if (wpNums.length === 1) {
        return [await this.fetchWaypoint(wpNums[0])];
      } else if (wpNums.length > 1) {
        const promises = [];

        wpNums.forEach(wpNum => {
          promises.push(this.fetchWaypoint(wpNum));
        });

        return await Promise.all(promises).catch(err => {
          console.error(err);
        });
      }
    }

    /**
     * Fetch one waypoint of records
     * @param {number} wpNum - The waypoint number to fetch
     * @returns {Object} - Waypoint object with the shape
     * `{ wpNum, records }` comprised of the waypoint number and an
     * object of records markup keyed by uri
     */
    async fetchWaypoint(wpNum) {
      const waypoint = document.querySelector(
        `.waypoint[data-waypoint-number='${wpNum}']:not(.populated)`
      );
      const query = new URLSearchParams();

      waypoint.dataset.uris.split(';').forEach(uri => {
        query.append('urls[]', uri);
      });

      const url = `${this.appUrlPrefix}${this.resourceUri}/infinite/waypoints?${query}`;

      try {
        const response = await fetch(url);
        const records = await response.json();
        return { wpNum, records };
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Append records markup to one or more waypoints, start observing
     * each record via `contentRecordObs`, clear the waypoint number(s)
     * from any data attributes, and conditionally run `updateShowingPercentage()`
     * @param {Object[]} waypoints - Array of waypoint objects as
     * returned from `fetchWaypoints()`, each of which represents one waypoint
     * with the signature `{ wpNum, records}`
     * @param {boolean} [updateShouldCloseModal=false] - Whether or not the
     * `updateShowingPercentage()`, called by `populateAllWaypoints()`, should
     * close the loading modal, defaults to false
     */
    populateWaypoints(waypoints, updateShouldCloseModal = false) {
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

          // The record container is all set up so inject fetched data
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

        if (this.loadAllSection)
          this.updateShowingPercentage(updateShouldCloseModal);
      });
    }

    /**
     * Conditionally set the `data-observe-for-waypoints` attr on all
     * records in a given waypoint with an empty neighbor (the values
     * of which are a stringified array of waypoint numbers of the empty
     * neighbors), and start observing each record to populate nearby
     * empty waypoints
     * @param {number[]} wpNums - Array of waypoint numbers to consider
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
     * Remove a waypoint number from all record data attributes that include
     * the waypoint number; remove the records's data attribute entirely
     * if the waypoint number is the only item in the attribute's value
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
          delete record.dataset.observeForWaypoints;

          this.waypointObserver.unobserve(record);
        }
      });
    }

    updateShowingPercentage(shouldCloseModal = false) {
      const percentLabel = document.querySelector('#load-all-showing-percent');
      const percentConvention = percentLabel.dataset.percentConvention;
      const numPresentRecords = this.container.querySelectorAll(
        '.infinite-record-record'
      ).length;
      const percentLoaded = Math.round(
        (numPresentRecords / this.NUM_TOTAL_RECORDS) * 100
      );

      percentLabel.classList.add('item-highlight');
      percentLabel.textContent = `${percentLoaded}${percentConvention}`;
      percentLabel.onanimationend = () => {
        percentLabel.classList.remove('item-highlight');
      };

      if (numPresentRecords === this.NUM_TOTAL_RECORDS) {
        $(this.loadAllSection).fadeOut(500);

        if (shouldCloseModal) this.modal.toggle();
      }
    }

    /**
     * Populate the remaining empty waypoints
     * @param {boolean} [shouldImmediatelyToggleModal=true] - Whether or not
     * the modal should be toggled when called, default is true
     */
    populateAllWaypoints(shouldImmediatelyToggleModal = true) {
      if (shouldImmediatelyToggleModal) this.modal.toggle();

      this.waypointObserver.disconnect();

      this.container.removeEventListener('scrollend', () => {
        this.isOkToObserve = true;
      });

      const waypointNums = Array.from(
        this.container.querySelectorAll('.waypoint:not(.populated)')
      ).map(waypoint => parseInt(waypoint.dataset.waypointNumber, 10));
      const shouldUseMainThread =
        waypointNums.length > 0 &&
        waypointNums.length <= this.MAIN_MAX_CONCURRENT_FETCHES;

      if (shouldUseMainThread) {
        this.renderWaypoints(waypointNums, null, false);
      } else {
        const worker = new Worker(this.workerPath);
        const waypointTuples = waypointNums.map(wpNum => [
          wpNum,
          this.container
            .querySelector(`.waypoint[data-waypoint-number='${wpNum}']`)
            .dataset.uris.split(';'),
        ]);

        worker.postMessage({
          waypointTuples,
          resourceUri: this.resourceUri,
          MAX_CONCURRENT_FETCHES: this.WORKER_MAX_CONCURRENT_FETCHES,
          appUrlPrefix: this.appUrlPrefix,
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
     * IntersectionObserver callback for the waypoint observer; pushes
     * unique empty waypoint numbers to the queue and starts processing
     * the queue if needed
     * @param {IntersectionObserverEntry[]} entries - Array of entries
     * @param {IntersectionObserver} observer - The observer
     */
    waypointScrollHandler(entries, observer) {
      entries.forEach(entry => {
        if (entry.isIntersecting && this.isOkToObserve) {
          const queueWasEmptyAtStart = this.wpQueueIsEmpty();
          const emptyWaypoints = entry.target.dataset.observeForWaypoints;
          const observingTargets = document.querySelectorAll(
            `[data-observe-for-waypoints="${emptyWaypoints}"]`
          );

          JSON.parse(emptyWaypoints).forEach(wpNum => {
            if (!this.wpQueue.includes(wpNum)) {
              this.wpQueue.push(wpNum);
            }
          });

          if (queueWasEmptyAtStart && !this.wpQueueIsEmpty()) {
            this.processWaypointQueue();
          }

          observingTargets.forEach(target => {
            target.removeAttribute('data-observe-for-waypoints');

            observer.unobserve(target);
          });
        }
      });
    }

    /**
     * Process the queue of waypoint numbers to render
     */
    processWaypointQueue() {
      let count = 0;

      while (!this.wpQueueIsEmpty()) {
        const openModal = count === 0;
        const closeModal = this.wpQueue.length === 1;

        this.renderWaypoints([this.wpQueue[0]], null, openModal, closeModal);

        this.wpQueue.shift();

        count++;
      }
    }

    /**
     * IntersectionObserver callback for current record observer
     * @param {IntersectionObserverEntry[]} entries - Array of entries
     */
    currentRecordScrollHandler(entries) {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const uri = entry.target.dataset.uri;
          const _new = document.querySelector(
            `#infinite-tree-container .table-row[data-uri="${uri}"]`
          );
          const old = document.querySelector(
            '#infinite-tree-container .table-row.current'
          );

          if (old) {
            old.classList.remove('current');
          }

          if (_new) {
            _new.classList.add('current');
          }
        }
      });
    }

    /**
     * Handle click events on record titles in the tree by scrolling to
     * the record if it exists, or rendering the record's waypoint and
     * nearby waypoints then scrolling to the record
     * @param {Event} event - The click event
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
        // Record doesn't exist so render its waypoint and any empty neighbors,
        // then scroll to the record
        const recordWaypointNum = this.treeIdToWaypointNumber(targetDivId);
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
     * Get the uri of a record given the treeId; useful since querying the DOM
     * for a string with `::` is messy.
     * @param {string} treeId - treeId of the record with or without a leading '#'
     * eg: #tree::archival_object_123
     * @returns {string} - Record URI, e.g. /repositories/2/archival_objects/123
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
     * Get the waypoint number of the record with the given treeId
     * @param {string} treeId - treeId of the record with or without a leading '#'
     * eg: #tree::archival_object_123
     * @returns {number} - Waypoint number
     */
    treeIdToWaypointNumber(treeId) {
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
     * Determine if the waypoint before the given waypoint is empty
     * @param {number} wpNum - Number of the waypoint with possible empty neighbor
     * @returns {boolean} - True if the waypoint before the given waypoint is empty
     */
    hasEmptyPrevWP(wpNum) {
      return wpNum > 0
        ? !this.container
            .querySelector(`.waypoint[data-waypoint-number='${wpNum - 1}']`)
            .classList.contains('populated')
        : false;
    }

    /**
     * Determine if the waypoint after the given waypoint is empty
     * @param {number} wpNum - Number of the waypoint with possible empty neighbor
     * @returns {boolean} - True if the waypoint after the given waypoint is empty
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
