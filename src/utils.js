
var jwt = require('jsonwebtoken');
var config = require('./config');

var exports = module.exports = {};

exports.createToken = function(profile) {
  var token = jwt.sign(
      {username: profile.username,
       id: profile.id},
      config.secret,
      { expiresIn: 60*100 });

  console.log(token);

  return token;
};

