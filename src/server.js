
var express = require('express');
var bodyParser = require('body-parser');
var cors = require('cors');
var errorhandler = require('errorhandler');
var logger = require('morgan');
var jwt = require('express-jwt');
var config = require('./config');

require('dotenv').load();

var app = express();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cors());

app.use(function(er, req, res, next) {
  if (err.name === 'StatusError') {
    res.send(err.status, err.message);
  } else {
    next(err);
  }
});

if (process.env.NODE_ENV === 'development') {
  app.use(logger('dev'));
  app.use(errorhandler());
}

// pull JSON webtoken payload out of authentication header and decode using our secret.
// Places decoded payload object in req.user.
//
var jwtCheck = jwt({
  secret: config.secret
});
app.use('/private', jwtCheck);

// routes
//
app.use(require('./user-routes'));
app.use(require('./session-routes'));
app.use(require('./notification-routes'));
app.use(require('./recipes-routes'));

var port = process.env.PORT || 3000;

var server = app.listen(port, function () {
  console.log('listening on port', port);
});

