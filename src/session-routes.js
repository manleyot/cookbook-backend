var express = require('express');
var pg = require('pg');

var config = require('./config')
var utils = require('./utils')

var app = module.exports = express.Router();

app.post('/sessions', function(req, res) {

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
    client.query('SELECT id, username, password FROM users WHERE username = $1', [req.body.username],
        function(err, result) {

          done();

          if(err) {
            return res.status(500).send("error executing database query");
          }

          if (result.rows.length != 1) {
            return res.status(409).send("invalid username or password: " + req.body.username);
          }

          var user = result.rows[0];
          profile = {
            id: user.id,
            username: user.username,
            password: user.password
          };

          if (req.body.password != profile.password) {
            console.log ("invalid password: " + req.body.password);
            return res.status(409).send("invalid username or password: " + req.body.username);
          }

          console.log(profile);

          res.status(201).send({
            token: utils.createToken(profile)
          });

        })
  });

});
