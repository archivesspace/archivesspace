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
          (e.name === 'QuotaExceededError' ||
            e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
          window.localStorage &&
          window.localStorage.length !== 0
        );
      }
    }
  }

  exports.LocalStorage = LocalStorage;
})(window);
