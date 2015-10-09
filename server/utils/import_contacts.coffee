Contact = require '../models/contact'
CompareContacts = require '../utils/compare_contacts'
async = require 'async'
realtimer = require './realtimer'
log = require('printit')(prefix: 'contactsimport')
im = require('imagemagick-stream')
_ = require 'lodash'
https = require('https')
url = require 'url'

access_token = null

numberProcessed = 0
total = 0

NotificationHelper = require 'cozy-notifications-helper'
notification = new NotificationHelper 'import-from-google'
localizationManager = require './localization_manager'

addContactToCozy = (gContact, cozyContacts, callback) ->
    log.debug "import 1 contact"
    fromGoogle = new Contact Contact.fromGoogleContact gContact

    name = fromGoogle.getName()
    log.debug "looking or #{name}"
    if name is ""
        numberProcessed += 1
        realtimer.sendContacts
            number: numberProcessed
            total: total

        callback null
    else

        # look for same, take the first one
        fromCozy = null
        for cozyContact in cozyContacts
            if CompareContacts.isSamePerson cozyContact, fromGoogle
                fromCozy = cozyContact
                break

        endCb = (err, updatedContact) ->
            log.debug "updated #{name} err=#{err}"
            return callback err if err
            numberProcessed += 1
            realtimer.sendContacts
                number: numberProcessed
                total: total
            callback null, updatedContact

        if fromCozy? #  merge
            log.debug "merging #{name}"
            toCreate = CompareContacts.mergeContacts fromCozy, fromGoogle
            toCreate.docType = 'contact'
            toCreate.save endCb

        else # create
            fromGoogle.revision = new Date().toISOString()
            log.debug "creating #{name}"
            Contact.create fromGoogle, endCb


PICTUREREL = "http://schemas.google.com/contacts/2008/rel#photo"
addContactPicture = (cozyContact, gContact, done) ->
    pictureLink = gContact.link.filter (link) -> link.rel is PICTUREREL
    pictureUrl = pictureLink[0]?.href

    return done null unless pictureUrl

    opts = url.parse(pictureUrl)
    opts.headers =
        'Authorization': 'Bearer ' + access_token
        'GData-Version': '3.0'
    https.get opts, (stream)->
        stream.on 'error', done
        unless stream.statusCode is 200
            log.warn "error fetching #{pictureUrl}", stream.statusCode
            return done null
        thumbStream = stream.pipe im().resize('300x300^').crop('300x300')
        thumbStream.on 'error', done
        thumbStream.path = 'useless'
        type = stream.headers['content-type']
        opts = {name: 'picture', type: type}
        cozyContact.attachFile thumbStream, opts, (err)->
            if err
                log.error "picture #{err}"
            else
                log.debug "picture ok"
            done err


listContacts = (callback) ->

    opts =
        host: 'www.google.com'
        port: 443
        path: '/m8/feeds/contacts/default/full?alt=json&max-results=10000'
        method: 'GET'
        headers:
            'Authorization': 'Bearer ' + access_token
            'GData-Version': '3.0'

    req = https.request opts, (res) ->
        data = []

        res.on 'error', callback
        res.on 'data', (chunk) -> data.push chunk
        res.on 'end', ->
            if res.statusCode is 200
                try
                    result = JSON.parse data.join('')
                    callback null, result.feed.entry
                catch err then callback err
            else
                callback new Error("Error #{res.statusCode}")


    req.on 'error', callback
    req.end()

# get a list of every contact of a google account
module.exports = (token, callback) ->
    access_token = token
    log.debug 'request contacts list'
    numberProcessed = 0

    async.parallel
        # google: dummyListContacts
        google: listContacts
        cozy: Contact.all
    , (err, contacts) ->
        log.debug "got #{contacts?.google?.length} contacts"
        return callback err if err
        total = contacts.google?.length
        updatedContacts = {}
        async.eachSeries contacts.google, (gContact, cb) ->
            addContactToCozy gContact, contacts.cozy, (err, updatedContact)->
                updatedContacts[gContact.id.$t] = updatedContact
                cb err
        , (err)->
            return callback err if err
            async.eachSeries contacts.google, (gContact, cb) ->
                updated = updatedContacts[gContact.id.$t]
                if updated?
                    addContactPicture updated, gContact, (err) ->
                        log.debug "picture err #{err}" if err
                        setTimeout cb, 10
                else
                    cb()
            , (err) ->
                return callback err if err

                _ = localizationManager.t
                notification.createOrUpdatePersistent "leave-google-contacts",
                    app: 'import-from-google'
                    text: _ 'notif_import_contact', total: total
                    resource:
                        app: 'contacts'
                        url: 'contacts/'
                callback()
