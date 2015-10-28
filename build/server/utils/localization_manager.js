// Generated by CoffeeScript 1.8.0
var LOCALE_PATH, LocalizationManager, Polyglot, cozydb, fs, path;

fs = require('fs');

Polyglot = require('node-polyglot');

cozydb = require('cozydb');

path = require('path');

LOCALE_PATH = path.resolve(__dirname, '../locales/');

LocalizationManager = (function() {
  function LocalizationManager() {}

  LocalizationManager.prototype.polyglot = null;

  LocalizationManager.prototype.initialize = function(callback) {
    return this.retrieveLocale((function(_this) {
      return function(err, locale) {
        if (err != null) {
          return callback(err);
        } else {
          _this.polyglot = _this.getPolyglotByLocale(locale);
          return callback(null, _this.polyglot);
        }
      };
    })(this));
  };

  LocalizationManager.prototype.retrieveLocale = function(callback) {
    return cozydb.api.getCozyLocale(function(err, locale) {
      if ((err != null) || !locale) {
        locale = 'en';
      }
      return callback(err, locale);
    });
  };

  LocalizationManager.prototype.getPolyglotByLocale = function(locale) {
    var err, phrases;
    try {
      phrases = require("" + LOCALE_PATH + "/" + locale);
    } catch (_error) {
      err = _error;
      phrases = require("" + LOCALE_PATH + "/en");
    }
    return new Polyglot({
      locale: locale,
      phrases: phrases
    });
  };

  LocalizationManager.prototype.t = function(key, params) {
    var _ref;
    if (params == null) {
      params = {};
    }
    return (_ref = this.polyglot) != null ? _ref.t(key, params) : void 0;
  };

  LocalizationManager.prototype.getPolyglot = function() {
    return this.polyglot;
  };

  return LocalizationManager;

})();

module.exports = new LocalizationManager();
