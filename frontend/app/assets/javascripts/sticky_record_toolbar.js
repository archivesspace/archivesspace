(function () {
  let observer = null;

  function init() {
    observer?.disconnect();
    observer = null;

    const stickyToolbar = document.querySelector('.sticky-record-toolbar');
    const heading = document.querySelector('.record-pane h2');
    if (!stickyToolbar || !heading) return;

    let stickyTitle = stickyToolbar.querySelector('.sticky-record-toolbar__title');
    if (!stickyTitle) {
      stickyTitle = document.createElement('div');
      // .h2 gives it the page heading's size without adding a second <h2>
      stickyTitle.className = 'sticky-record-toolbar__title h2';
      stickyTitle.setAttribute('aria-hidden', 'true');
      stickyToolbar.appendChild(stickyTitle);
    }

    const copy = heading.cloneNode(true);
    copy.querySelectorAll('[id]').forEach(el => el.removeAttribute('id'));
    stickyTitle.replaceChildren(...copy.childNodes);
    stickyTitle.title = heading.textContent.replace(/\s+/g, ' ').trim();

    const toolbarHeight =
      stickyToolbar.querySelector('.record-toolbar').offsetHeight;
    observer = new IntersectionObserver(
      ([entry]) => {
        const scrolledPast =
          !entry.isIntersecting &&
          entry.boundingClientRect.top < entry.rootBounds.top;
        stickyToolbar.classList.toggle('is-stuck', scrolledPast);
      },
      { rootMargin: `-${toolbarHeight}px 0px 0px 0px` }
    );
    observer.observe(heading);
  }

  document.addEventListener('DOMContentLoaded', init);
  $(document).on('loadedrecordform.aspace', init);
})();
