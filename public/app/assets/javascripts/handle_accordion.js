/* handle the accordions */
/* we need to pass in the text that is obtained via the config/locales/*yml file */
let expandLabel = '';
let collapseLabel = '';
/* we don't provide a button if there's only one panel; neither do we collapse that one panel */

/**
 * @param {string} accordionCollapseSelector accordion collapse selector
 * @param {string} expandLabelText expand text from i18n
 * @param {string} collapseLabelText collapse text from i18n
 * @param {boolean} expandOnLoad
 */
function initialize_accordion(
  accordionCollapseSelector,
  expandLabelText,
  collapseLabelText,
  expandOnLoad
) {
  expandLabel = expandLabelText;
  collapseLabel = collapseLabelText;

  const collapseElements = getAccordionCollapseElements(
    accordionCollapseSelector
  );
  const accordionHolder = getSingleAccordionHolder(collapseElements);

  if (collapseElements.length <= 1 || !accordionHolder) {
    return;
  }

  if (!accordionHolder.querySelector(':scope > .acc_button')) {
    const button = document.createElement('a');
    button.className = 'btn btn-primary acc_button mb-2';
    button.setAttribute('role', 'button');
    button.setAttribute('href', '#');
    accordionHolder.prepend(button);
  }

  expandAllByDefault(accordionCollapseSelector, expandOnLoad);
}

/**
 * @param {string} accordionCollapseSelector accordion collapse selector
 * @returns {HTMLElement[]} matching accordion collapse elements
 */
function getAccordionCollapseElements(accordionCollapseSelector) {
  return Array.from(document.querySelectorAll(accordionCollapseSelector));
}

/**
 * @param {HTMLElement[]} collapseElements accordion collapse elements
 * @returns {HTMLElement|null} shared accordion holder when exactly one is present
 */
function getSingleAccordionHolder(collapseElements) {
  const holders = Array.from(
    new Set(
      collapseElements
        .map(collapseElement => collapseElement.closest('.acc_holder'))
        .filter(holder => holder !== null)
    )
  );

  return holders.length === 1 ? holders[0] : null;
}

/**
 * @param {string} accordionCollapseSelector accordion collapse selector
 * @param {boolean} shouldExpand whether accordion should expand
 */
function expandAllByDefault(accordionCollapseSelector, shouldExpand) {
  setAccordionExpandedState(accordionCollapseSelector, shouldExpand);
}

/**
 * @param {string} accordionCollapseSelector accordion collapse selector
 * @param {boolean} shouldExpand whether accordion should expand
 */
function setAccordionExpandedState(accordionCollapseSelector, shouldExpand) {
  const collapseElements = getAccordionCollapseElements(
    accordionCollapseSelector
  );

  collapseElements.forEach(collapseElement => {
    toggleAccordionCollapse(collapseElement, shouldExpand);
  });

  updateAccordionToggleButton(
    collapseElements,
    accordionCollapseSelector,
    !shouldExpand
  );
}

/**
 * @param {HTMLElement} collapseElement accordion collapse element
 * @param {boolean} shouldExpand whether element should expand
 */
function toggleAccordionCollapse(collapseElement, shouldExpand) {
  const instance = window.bootstrap.Collapse.getOrCreateInstance(
    collapseElement,
    {
      toggle: false,
    }
  );

  if (shouldExpand) {
    instance.show();
  } else {
    instance.hide();
  }
}

/**
 * @param {HTMLElement[]} collapseElements accordion collapse elements
 * @param {string} accordionCollapseSelector accordion collapse selector
 * @param {boolean} shouldExpand whether button should trigger expand
 */
function updateAccordionToggleButton(
  collapseElements,
  accordionCollapseSelector,
  shouldExpand
) {
  const accordionHolder = getSingleAccordionHolder(collapseElements);

  if (!accordionHolder) {
    return;
  }

  const toggleButton = accordionHolder.querySelector(':scope > .acc_button');

  if (!toggleButton) {
    return;
  }

  toggleButton.textContent = shouldExpand ? expandLabel : collapseLabel;
  toggleButton.setAttribute('href', '#');
  toggleButton.onclick = event => {
    event.preventDefault();
    setAccordionExpandedState(accordionCollapseSelector, shouldExpand);
  };
}
