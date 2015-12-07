var express = require('express');
var pg = require('pg');

var config = require('./config')
var utils = require('./utils')

var app = module.exports = express.Router();

function addUser (client, username, password, then) {

  client.query('INSERT INTO users (username, password) VALUES ($1, $2) RETURNING id', [username, password],
      function(err, result) {
        if(err) {
          then(err, null);
        }

        if (result.rows.length < 1) {
          then("no ID returned from query", null);
        }

        then(null, {
          id: result.rows[0].id,
          username: username,
          password: password
        });

      });

}

app.post('/users', function(req, res) {

  if (!req.body.username | !req.body.password){
    return res.status(400).send("missing username and/or password");
  }

  // check user in database
  //
  pg.connect(config.db, function(err, client, done) {
    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }
    client.query('SELECT (id, username, password) FROM users WHERE username = $1', [req.body.username],
        function(err, result) {

          if(err) {
            done();
            console.log (err);
            return res.status(500).send("error executing database query");
          }

          if (result.rows.length > 0) {
            done();
            return res.status(409).send("username: " + req.body.username + " already exists");
          }

          addUser (client, req.body.username, req.body.password, function(err, profile) {
            done();

            if (err) {
              return res.status(500).send("failed to add new user");
            }

            console.log(profile);

            res.status(201).send({
              token: utils.createToken(profile)
            });

          });

        })
  });

});
