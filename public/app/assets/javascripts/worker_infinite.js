// Chromium has a limit of 1350 fetches per process, anything more and
// it throws a `net::ERR_INSUFFICIENT_RESOURCES` error, returning `undefined`
// per fetch. Here we use ES5 syntax (to appease Uglifier) to mimic an ES6
// async generator that fetches waypoints in batches. The smaller the
// batch size the more frequent the user feedback re: loading progress.
const MAX_FETCHES_PER_PROCESS = 300;

/**
 * @typedef {array} waypointTuple - Array containing a waypoint number and an
 * array of record URI strings
 * @typedef {number} waypointTuple[0] - Waypoint number
 * @typedef {string[]} waypointTuple[1] - Array of record URI strings
 */

/**
 * Handle the `message` event from the main thread
 * @param {Object} e - Event object
 * @param {array} e.data.waypointTuples - Array of waypoint tuples
 * @param {string} e.data.resourceUri - The resource URI
 */
onmessage = function (e) {
  const waypointTuples = e.data.waypointTuples;
  const resourceUri = e.data.resourceUri;
  const chunks = chunkGenerator(waypointTuples, MAX_FETCHES_PER_PROCESS);

  iterateChunks(chunks, resourceUri, 0);
};

/**
 * Send fetched waypoint data to the main thread in chunks via recursive
 * ES5 syntax in place of ES6 `for await...of` loop
 * @param {array} chunks - Array of waypoint tuples
 * @param {string} resourceUri - The resource URI
 * @param {number} i - Index of the current chunk
 */
function iterateChunks(chunks, resourceUri, i) {
  let done = false;

  if (i < chunks.length) {
    fetchChunks(chunks[i], resourceUri, data => {
      postMessage({ data, done });

      setTimeout(iterateChunks, 0, chunks, resourceUri, i + 1);
    });
  } else {
    done = true;
    postMessage({ done });
  }
}

/**
 * ES5 generator pattern to chunk an array into smaller arrays
 * @param {array} arr - Array to chunk
 * @param {number} size - Size of chunks
 * @returns {array} - Array of arrays of size `size`
 */
function chunkGenerator(arr, size) {
  let i = 0;
  const chunks = [];

  while (i < arr.length) {
    chunks.push(arr.slice(i, i + size));
    i += size;
  }

  return chunks;
}

/**
 * Fetch a chunk of waypoint data to send to main thread via the callback
 * @param {array} chunk - Array of waypoint tuples
 * @param {string} resourceUri - The resource URI
 * @param {Function} callback - Callback to call with fetched data
 */
function fetchChunks(chunk, resourceUri, callback) {
  const promises = chunk.map(waypointTuple =>
    fetchWaypoint(waypointTuple[0], waypointTuple[1], resourceUri)
  );

  Promise.all(promises)
    .then(results => {
      callback(results);
    })
    .catch(err => {
      console.error(err);
    });
}

/**
 * Fetch data for one waypoint
 * @param {number} wpNum - Waypoint number
 * @param {array} uris - Array of URIs to fetch
 * @param {string} resourceUri - The resource URI
 * @returns {Promise} - Resolves to an array of objects with
 * a waypoint number and an object of records markup keyed by URI
 */
function fetchWaypoint(wpNum, uris, resourceUri) {
  const origin = self.location.origin;
  const query = new URLSearchParams();

  uris.forEach(uri => {
    query.append('urls[]', uri);
  });

  const url = `${origin}${resourceUri}/infinite/waypoints?${query}`;

  return fetch(url)
    .then(response => response.json())
    .then(records => ({ wpNum, records }))
    .catch(err => {
      console.error(err);
    });
}
