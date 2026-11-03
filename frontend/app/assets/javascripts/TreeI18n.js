(function (exports) {
  /**
   * InfiniteTreeI18n encapsulates i18n logic for InfiniteTree rendering.
   *
   * @class
   * @param {Object} options
   * @param {string} options.sep - The identifier separator string
   * @param {string} options.bulk - The bulk date string
   * @param {Object} options.enumerations - The enumeration translations object
   * @param {string} options.expand - Expand button label
   * @param {string} options.collapse - Collapse button label
   */
  class InfiniteTreeI18n {
    constructor({ sep, bulk, enumerations, expand, collapse }) {
      this.sep = sep;
      this.bulk = bulk;
      this.enumerations = enumerations.ENUMERATION_TRANSLATIONS;
      this.expand = expand;
      this.collapse = collapse;
    }

    /**
     * Fills `%{title}` in the expand or collapse button label pattern
     * @param {'expand'|'collapse'} action - Which label
     * @param {string} title - The node title as plain text
     * @returns {string} - The label
     */
    toggleLabel(action, title) {
      return this[action].replace('%{title}', () => title);
    }

    /**
     * @param {string} enumeration - The enumeration name
     * @param {string} enumeration_value - The enumeration value
     * @returns {string|null} The translated value or null if not found
     */
    t(enumeration, enumeration_value) {
      const translation = this.enumerations?.[enumeration]?.[enumeration_value];
      if (translation !== undefined) {
        return translation;
      } else if (enumeration === 'archival_record_level') {
        return enumeration_value;
      }
      return null;
    }
  }

  exports.InfiniteTreeI18n = InfiniteTreeI18n;
})(window);
