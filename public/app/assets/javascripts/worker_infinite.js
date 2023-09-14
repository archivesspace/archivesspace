// Chrome seems to have a max of 1350 fetches per process, anything more and
// it throws a `net::ERR_INSUFFICIENT_RESOURCES` error. Here we use an
// async generator to fetch waypoints in batches. Don't go over 1350 batch size,
// 1000 takes a while, use a smaller number for more frequent feedback to the
// user about loading progress (lower number probably helps with memory usage too
// as there is less to append to the DOM each iteration).
const MAX_FETCHES_PER_PROCESS = 300;

onmessage = async e => {
  const { waypointTuples, resourceUri } = e.data;
  const chunks = chunkGenerator(waypointTuples, MAX_FETCHES_PER_PROCESS);

  let done = false;

  for await (let chunk of chunks) {
    postMessage({ data: chunk, done });
  }

  done = true;

  postMessage({ done });

  async function* chunkGenerator(arr, size) {
    for (let i = 0; i < arr.length; i += size) {
      yield await fetchWaypoints(arr.slice(i, i + size), resourceUri);
    }
  }
};

/**
 * fetchWaypoints
 * @description Fetch one or more waypoints of records
 * @param {string} resourceUri - The uri of the collection resource,
 * ie: /repositories/18/resources/11861
 * @param {[wpNum, uris]} waypointTuples - Array of tuples of waypoint metadata
 * @typedef {number} wpNum - The waypoint number
 * @typedef {string[]} uris - Array of record uris belonging to the waypoint
 * @returns {Promise} - A Promise that resolves to an array of waypoint
 * objects, each with the signature: `{ wpNum, records }`
 */
async function fetchWaypoints(waypointTuples, resourceUri) {
  const promises = waypointTuples.map(tuple =>
    fetchWaypoint(...tuple, resourceUri)
  );

  return await Promise.all(promises).catch(err => {
    console.error(err);
  });
}

/**
 * fetchWaypoint
 * @description Fetch a waypoint of records
 * @param {number} wpNum - the waypoint number to fetch
 * @param {string[]} uris - Array of record uris belonging to the waypoint
 * @param {string} resourceUri - The uri of the collection resource,
 * ie: /repositories/18/resources/11861
 * @returns {Promise} - Promise that resolves with the waypoint object made up of
 * keys of record uris and values of record markup
 */
async function fetchWaypoint(wpNum, uris, resourceUri) {
  const origin = self.location.origin;
  const query = new URLSearchParams();

  uris.forEach(uri => {
    query.append('urls[]', uri);
  });

  const url = `${origin}${resourceUri}/infinite/waypoints?${query}`;

  try {
    const response = await fetch(url);
    const records = await response.json();

    return { wpNum, records };
  } catch (err) {
    console.error(err);
  }
}
