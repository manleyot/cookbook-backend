var express = require('express');
var pg = require('pg');

var config = require('./config')

var app = module.exports = express.Router();

app.get('/private/:username/notifications', function(req, res) {

  if (req.params.username != req.user.username) {
    //TODO: check database access list
    return res.status(401).send("You don't have access to view notifications for user: " + req.params.username);
  }

  pg.connect(config.db, function(err, client, done) {

    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }

    var limit = req.query.limit ? (parseInt(req.query.limit) + 1).toString() : "100";
    var offset = req.query.offset ? req.query.offset : "0";

    client.query('SELECT * FROM notifications WHERE userId = $1::bigint ORDER BY id DESC LIMIT $2 OFFSET $3',
        [req.user.id, limit, offset],
        function(err, result) {
          done();

          if(err) {
            console.log(err);
            return res.status(500).send("error executing database query");
          }

          var notificationList = [];

          var nRows = result.rows.length;
          for (var i = 0; i < nRows; i++) {

            var notification = {
              time: result.rows[i].time,
              message: result.rows[i].message,
              notificationType: result.rows[i].notificationtype
            };

            notificationList.push(notification);
          }

          // determine if there are more results available for the user
          // if they were to increase their offset or limit
          //
          var moreResults = false;
          if (notificationList.length >= parseInt(limit)) {
            moreResults = true;
            notificationList.pop();
          }

          return res.status(200).send(JSON.stringify({
            more: moreResults,
            notifications: notificationList
          }));
        });
  });
});

