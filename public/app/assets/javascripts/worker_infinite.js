// Chrome seems to have a max of 1350 fetches per process, anything more and
// it throws a `net::ERR_INSUFFICIENT_RESOURCES` error. Here we use an
// async generator to fetch waypoints in batches. Don't go over 1350 batch size,
// 1000 takes a while, use a smaller number for more frequent feedback to the
// user about loading progress (lower number probably helps with memory usage too
// as there is less to append to the DOM each iteration).
const MAX_FETCHES_PER_PROCESS = 300;

onmessage = function (e) {
  const waypointTuples = e.data.waypointTuples;
  const resourceUri = e.data.resourceUri;
  const chunks = chunkGenerator(waypointTuples, MAX_FETCHES_PER_PROCESS);

  let done = false;
  let index = 0;

  processChunks();

  function processChunks() {
    if (index < chunks.length) {
      fetchChunks(chunks[index], resourceUri, data => {
        postMessage({ data, done });
        index++;
        setTimeout(processChunks, 0);
      });
    } else {
      done = true;
      postMessage({ done });
    }
  }
};

function chunkGenerator(arr, size) {
  let i = 0;
  const chunks = [];

  while (i < arr.length) {
    chunks.push(arr.slice(i, i + size));
    i += size;
  }

  return chunks;
}

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
