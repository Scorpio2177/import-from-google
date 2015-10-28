// Generated by CoffeeScript 1.8.0
var Album, cozydb;

cozydb = require('cozydb');

module.exports = Album = cozydb.getModel('Account', {
  label: String,
  name: String,
  login: String,
  password: String,
  accountType: String,
  oauthProvider: String,
  oauthRefreshToken: String,
  oauthAccessToken: String,
  initialized: Boolean,
  smtpServer: String,
  smtpPort: Number,
  smtpSSL: Boolean,
  smtpTLS: Boolean,
  smtpLogin: String,
  smtpPassword: String,
  smtpMethod: String,
  imapLogin: String,
  imapServer: String,
  imapPort: Number,
  imapSSL: Boolean,
  imapTLS: Boolean,
  inboxMailbox: String,
  flaggedMailbox: String,
  draftMailbox: String,
  sentMailbox: String,
  trashMailbox: String,
  junkMailbox: String,
  allMailbox: String,
  favorites: [String],
  patchIgnored: Boolean,
  signature: String
});
