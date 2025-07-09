(function (exports) {
  /**
   * InfiniteTreeI18n encapsulates i18n logic for InfiniteTree rendering.
   *
   * @class
   * @param {Object} options
   * @param {string} options.sep - The identifier separator string
   * @param {string} options.bulk - The bulk date string
   * @param {Object} options.enumerations - The enumeration translations object
   */
  class InfiniteTreeI18n {
    constructor({ sep, bulk, enumerations }) {
      this.sep = sep;
      this.bulk = bulk;
      this.enumerations = enumerations.ENUMERATION_TRANSLATIONS;
    }

    /**
     * @param {string} enumeration - The enumeration name
     * @param {string} enumeration_value - The enumeration value
     * @returns {string|null} The translated value or null if not found
     */
    t(enumeration, enumeration_value) {
      if (this.enumerations.hasOwnProperty(enumeration)) {
        if (this.enumerations[enumeration].hasOwnProperty(enumeration_value)) {
          return this.enumerations[enumeration][enumeration_value];
        } else if (enumeration === 'archival_record_level') {
          return enumeration_value;
        }
      }
      return null;
    }
  }

  exports.InfiniteTreeI18n = InfiniteTreeI18n;
})(window);
