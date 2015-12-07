var express = require('express');
var pg = require('pg');

var config = require('./config')

var app = module.exports = express.Router();

app.get('/private/:username/recipes', function(req, res) {

  if (req.params.username != req.user.username) {
    //TODO: check database access list
    return res.status(401).send("You don't have access to view recipes owned by: " + req.params.username);
  }

  pg.connect(config.db, function(err, client, done) {

    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }

    var limit = req.query.limit ? (parseInt(req.query.limit) + 1).toString() : "100";
    var offset = req.query.offset ? req.query.offset : "0";

    client.query('SELECT id, name FROM recipes WHERE ownerId = $1::bigint ORDER BY name LIMIT $2 OFFSET $3',
        [req.user.id, limit, offset],
        function(err, result) {
          done();

          if(err) {
            console.log(err);
            return res.status(500).send("error executing database query");
          }

          var recipeList = [];

          var nRows = result.rows.length;
          for (var i = 0; i < nRows; i++) {
            var recipe = {
              id: result.rows[i].id,
              name: result.rows[i].name
            };

            recipeList.push(recipe);
          }

          // determine if there are more results available for the user
          // if they were to increase their offset or limit
          //
          var moreResults = false;
          if (recipeList.length >= parseInt(limit)) {
            moreResults = true;
            recipeList.pop();
          }

          return res.status(200).send(JSON.stringify({
            more: moreResults,
            recipes: recipeList
          }));
        });
  });
});

app.get('/private/:username/recipes/:id', function(req, res) {

  if (req.params.username != req.user.username) {
    //TODO: check database access list
    return res.status(401).send("You don't have access to view recipes owned by: " + req.params.username);
  }

  pg.connect(config.db, function(err, client, done) {

    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }


    client.query('SELECT * FROM recipes WHERE ownerId = $1::bigint AND id = $2::bigint',
        [req.user.id, req.params.id],
        function(err, result) {
          done();

          if(err) {
            console.log(err);
            return res.status(500).send("error executing database query");
          }

          var recipe = null;

          if (result.rows.length != 1) {
            return res.status(500).send("invalide query results");
          }

          recipe = result.rows[0].data;
          recipe.name = result.rows[0].name;

          return res.status(200).send(JSON.stringify(recipe));
        });
  });
});

app.get('/private/:username/recipes/:id/notes', function(req, res) {

  if (req.params.username != req.user.username) {
    return res.status(401).send("You don't have access to edit recipes owned by: " + req.params.username);
  }

  pg.connect(config.db, function(err, client, done) {

    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }

    client.query('SELECT note FROM recipe_notes AS N, recipes AS R WHERE R.id = N.recipeId AND R.id = $1::bigint AND R.ownerId = $2::bigint',
        [req.params.id, req.user.id],
        function(err, result) {
          done();

          if(err) {
            console.log(err);
            return res.status(500).send("error executing database query");
          }

          var notes = [];

          var nRows = result.rows.length;
          for (var i = 0; i < nRows; i++) {
            notes.push(result.rows[i].note);
          }

          return res.status(200).send(JSON.stringify(notes));
        });
  });
});

app.post('/private/:username/recipes/:id/notes', function(req, res) {

  if (req.params.username != req.user.username) {
    return res.status(401).send("You don't have access to edit recipes owned by: " + req.params.username);
  }

  pg.connect(config.db, function(err, client, done) {

    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }

    // make sure this user owns the recipe
    //
    client.query('SELECT id FROM recipes WHERE id = $1::bigint AND ownerId = $2::bigint',
      [req.params.id, req.user.id],
      function(err, result) {

        if (err) {
          done();
          console.log(err);
          return res.status(500).send("error executing database query");
        }

        if (result.rows.length != 1) {
          done();
          return res.status(401).send("cannot modify recipe: " + req.params.id);
        }

        client.query('INSERT INTO recipe_notes (recipeId, note) VALUES ($1::bigint, $2::text)',
          [req.params.id, req.body.note],
          function(err, result) {
            done();

            if(err) {
              console.log(err);
              return res.status(500).send("error executing database query");
            }

            return res.status(200).send("{}");
          });
      });
  });

});

app.delete('/private/:username/recipes/:id', function(req, res) {

  if (req.params.username != req.user.username) {
    //TODO: check database access list
    return res.status(401).send("You don't have access to modify recipes owned by: " + req.params.username);
  }

  pg.connect(config.db, function(err, client, done) {

    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }

    client.query('DELETE FROM recipes WHERE ownerId = $1::bigint AND id = $2::bigint RETURNING *',
        [req.user.id, req.params.id],
        function(err, result) {
          done();

          if(err) {
            console.log(err);
            return res.status(500).send("error executing database query");
          }

          if (result.rows.length != 1) {
            return res.status(400).send("failed to delete requested recipe: " + req.params.id);
          }

          return res.status(200).send("{}");
        });
  });
});


app.post('/private/:username/recipes', function(req, res) {

  if (req.params.username != req.user.username) {
    //TODO: check database access list
    return res.status(401).send("You don't have access to edit recipes owned by: " + req.params.username);
  }

  pg.connect(config.db, function(err, client, done) {

    if (err) {
      console.log(err);
      return res.status(500).send("failed to connect to database");
    }

    client.query('INSERT INTO recipes (ownerId, name, data) VALUES ($1::bigint, $2::text, $3::json)',
        [req.user.id, req.body.name, JSON.stringify(req.body)],
        function(err, result) {
          done();

          if(err) {
            console.log(err);
            return res.status(500).send("error executing database query");
          }

          return res.status(200).send("{}");
        });
  });

});
