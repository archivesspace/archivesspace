(function (exports) {
  class MixedContent {
    /**
     * @constructor
     * @description - This class checks if a string has mixed content, and if so
     * provides the derived string without the HTML. MixedContent refers to a string
     * of content from the backend that includes embedded HTML tags with attributes
     * that are intended to render some or all content within the string with extra
     * CSS styles that would not otherwise be applied to the content via some
     * template. In ArchivesSpace, mixed content usually relates to use of Encoded
     * Archival Description (EAD), a standard for encoding archival finding aids, via
     * the `allow_mixed_content_title_fields` config option. The HTML often looks like
     * `<span class="emph render-none">Some text content</span>`, and can be pre and
     * proceeded by arbitrary text as well.
     * @param {string} input - A string that might contain mixed content
     * @returns {MixedContent} - A MixedContent object
     */
    constructor(input) {
      this.input = input;

      this.regex = /([^<]*)<span[^>]*>(.*?)<\/span>(.*)/;
      /**
       * ⚠ Assumes the HTML is a <span> tag with attributes:
       *
       * ([^<]*) - Capture anything before the <span> tag's opening <
       *
       * <span[^>]*> - Match <span, followed by any characters that are not >, and match >;
       * used to match the opening of the <span> tag and any arbitrary attributes it may have
       *
       * (.*?) - Match and capture all text content between the <span> and </span> tags
       *
       * <\/span> - Match the closing </span> tag
       *
       * (.*) - Match and capture anything after the </span> tag
       */

      this.match = this.input.match(this.regex);
    }

    /**
     * @description - Determine if the string has mixed content
     * @returns {boolean} - True if the string has mixed content
     */
    get isMixed() {
      if (!this.match) {
        return false;
      }

      return true;
    }

    /**
     * @description - Get the derived string without the HTML
     * @returns {string} - The derived string without HTML
     */
    get derivedString() {
      if (!this.match) {
        return this.input;
      }

      return this.match[1] + this.match[2] + this.match[3];
    }
  }

  exports.MixedContent = MixedContent;
})(window);
