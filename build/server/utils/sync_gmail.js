// Generated by CoffeeScript 1.9.3
var Account, google, log, oauth2Client, plus;

Account = require('../models/account');

google = require('googleapis');

plus = google.plus('v1');

oauth2Client = require('./google_access_token').oauth2Client;

log = require('printit')({
  date: true,
  prefix: 'utils:gmail'
});

module.exports = function(access_token, refresh_token, force, callback) {
  oauth2Client.setCredentials({
    access_token: access_token
  });
  return plus.people.get({
    userId: 'me',
    auth: oauth2Client
  }, function(err, profile) {
    var account, email, ref;
    if (err) {
      log.error(err);
      return callback(err);
    }
    if (!(profile != null ? (ref = profile.emails) != null ? ref.length : void 0 : void 0)) {
      return callback(null);
    }
    account = {
      label: "GMAIL oauth2",
      name: profile.displayName,
      login: profile.emails[0].value,
      oauthProvider: "GMAIL",
      initialized: false,
      oauthAccessToken: access_token,
      oauthRefreshToken: refresh_token
    };
    email = profile.emails[0].value;
    return Account.request('byEmailWithOauth', {
      key: email
    }, function(err, fetchedAccounts) {
      var newAttr;
      if (err) {
        log.error(err);
        return callback(err);
      }
      if (fetchedAccounts.length !== 0) {
        newAttr = {
          oauthRefreshToken: refresh_token
        };
        return fetchedAccounts[0].updateAttributes(newAttr, function(err) {
          return callback(err, fetchedAccounts[0]);
        });
      } else if (force) {
        return Account.create(account, function(err, account) {
          return callback(err, account);
        });
      } else {
        return callback();
      }
    });
  });
};
