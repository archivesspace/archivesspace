(function (exports) {
  class LocalStorage {
    get(key) {
      if (!this.storageAvailable()) return null;
      return window.localStorage.getItem(key);
    }

    set(key, value) {
      if (!this.storageAvailable()) return;
      window.localStorage.setItem(key, value);
    }

    remove(key) {
      if (!this.storageAvailable()) return;
      window.localStorage.removeItem(key);
    }

    getJSON(key) {
      const value = this.get(key);
      if (!value) return null;
      try {
        return JSON.parse(value);
      } catch (e) {
        return null;
      }
    }

    setJSON(key, value) {
      this.set(key, JSON.stringify(value));
    }

    /**
     * @returns {boolean} true if localStorage is available
     * @author https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API#testing_for_availability
     */
    storageAvailable() {
      try {
        const x = '__storage_test__';
        window.localStorage.setItem(x, x);
        window.localStorage.removeItem(x);
        return true;
      } catch (e) {
        return (
          e instanceof DOMException &&
          // everything except Firefox
          (e.code === 22 ||
            // Firefox
            e.code === 1014 ||
            // test name field too, because code might not be present
            // everything except Firefox
            e.name === 'QuotaExceededError' ||
            // Firefox
            e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
          // acknowledge QuotaExceededError only if there's something already stored
          window.localStorage &&
          window.localStorage.length !== 0
        );
      }
    }
  }

  exports.LocalStorage = LocalStorage;
})(window);
