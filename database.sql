
DROP DATABASE IF EXISTS cookbook;

CREATE DATABASE cookbook;

\c cookbook

CREATE TABLE users (
  id bigserial,
  username text NOT NULL,
  password text NOT NULL,
  PRIMARY KEY(id)
);

CREATE TABLE recipes (
  id bigserial,
  ownerId bigint NOT NULL,
  name text NOT NULL,
  data json,
  PRIMARY KEY(id),
  FOREIGN KEY(ownerId) REFERENCES users (id)
);

CREATE TABLE meals (
  id bigserial,
  userId bigint NOT NULL,
  name text NOT NULL,
  date date,
  PRIMARY KEY(id),
  UNIQUE(userId, name, date),
  FOREIGN KEY(userId) REFERENCES users (id)
);

CREATE TABLE meal_recipes (
  mealId bigint NOT NULL,
  recipeId bigint NOT NULL,
  PRIMARY KEY(mealId, recipeId)
);

CREATE TABLE recipe_notes (
  id bigserial,
  recipeId bigint NOT NULL,
  note text NOT NULL,
  PRIMARY KEY(id),
  FOREIGN KEY(recipeId) REFERENCES recipes (id)
);

CREATE FUNCTION remove_recipe_notes() RETURNS trigger AS $remove_recipe_notes$
  BEGIN
    DELETE FROM recipe_notes WHERE recipeId = OLD.id;
    RETURN OLD;
  END;
$remove_recipe_notes$ LANGUAGE plpgsql;

CREATE TRIGGER remove_recipe_notes_trigger
  BEFORE DELETE ON recipes
  FOR EACH ROW
  EXECUTE PROCEDURE remove_recipe_notes();


CREATE TYPE NotificationType AS ENUM(
  'user',
  'add',
  'remove',
  'meal',
  'note'
);

CREATE TABLE notifications (
  id bigserial,
  userId bigint NOT NULL,
  time timestamp with time zone default current_timestamp NOT NULL,
  notificationType NotificationType,
  message text,
  PRIMARY KEY(id),
  FOREIGN KEY(userId) REFERENCES users (id)
);

CREATE FUNCTION add_new_user_notification() RETURNS trigger AS $add_new_user_notification$
  BEGIN
    INSERT INTO notifications (userId, notificationType, message) VALUES (
      NEW.id,
      'user',
      'Created user: ' || NEW.username
    );
    RETURN NULL;
  END;
$add_new_user_notification$ LANGUAGE plpgsql;

CREATE TRIGGER add_new_user_notification_trigger
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE PROCEDURE add_new_user_notification();


CREATE FUNCTION add_new_recipe_notification() RETURNS trigger AS $add_new_recipe_notification$
  BEGIN
    INSERT INTO notifications (userId, notificationType, message) VALUES (
      NEW.ownerId,
      'add',
      'Created new recipe: ' || NEW.name
    );
    RETURN NULL;
  END;
$add_new_recipe_notification$ LANGUAGE plpgsql;

CREATE TRIGGER add_new_recipe_notification_trigger
  AFTER INSERT ON recipes
  FOR EACH ROW
  EXECUTE PROCEDURE add_new_recipe_notification();

CREATE FUNCTION add_delete_recipe_notification() RETURNS trigger AS $add_delete_recipe_notification$
  BEGIN
    INSERT INTO notifications (userId, notificationType, message) VALUES (
      OLD.ownerId,
      'remove',
      'Deleted recipe: ' || OLD.name
    );
    RETURN NULL;
  END;
$add_delete_recipe_notification$ LANGUAGE plpgsql;

CREATE TRIGGER add_delete_recipe_notification_trigger
  AFTER DELETE ON recipes
  FOR EACH ROW
  EXECUTE PROCEDURE add_delete_recipe_notification();

CREATE FUNCTION add_new_meal_notification() RETURNS trigger AS $add_new_meal_notification$
  BEGIN
    INSERT INTO notifications (userId, notificationType, message) VALUES (
      NEW.userId,
      'meal',
      'Created meal: ' || NEW.name || ' on ' || NEW.date
    );
    RETURN NULL;
  END;
$add_new_meal_notification$ LANGUAGE plpgsql;

CREATE TRIGGER add_new_meal_notification_trigger
  AFTER INSERT ON meals
  FOR EACH ROW
  EXECUTE PROCEDURE add_new_meal_notification();

CREATE FUNCTION add_new_recipe_note_notification() RETURNS trigger AS $add_new_recipe_note_notification$
  DECLARE
    recipeName text;
    userId bigint;
    summary text;
  BEGIN
    SELECT name INTO recipeName FROM recipes WHERE id = NEW.recipeId;
    SELECT ownerId INTO userId FROM recipes WHERE id = NEW.recipeId;

    -- limit to 80 chars
    IF char_length(NEW.note) <= 80 THEN
      summary := NEW.note;
    ELSE
      summary := substring(NEW.note from 0 for 77) || '...';
    END IF;

    INSERT INTO notifications (userId, notificationType, message) VALUES (
      userId,
      'note',
      recipeName || ': ' || summary
    );
    RETURN NULL;
  END;
$add_new_recipe_note_notification$ LANGUAGE plpgsql;

CREATE TRIGGER add_new_recipe_note_notification_trigger
  AFTER INSERT ON recipe_notes
  FOR EACH ROW
  EXECUTE PROCEDURE add_new_recipe_note_notification();



INSERT INTO users (username, password) VALUES ('manley', 'owen') RETURNING id;

SELECT * FROM users;

INSERT INTO recipes (ownerId, name, data) VALUES (
  1, 'recipe1',
  '{
    "description":"a recipe to make things",
    "ingredients":[
      "green beans",
      "onions"
    ],
    "steps":[
      "step 1",
      "step 2",
      "step 3"
    ]
   }');
INSERT INTO recipes (ownerId, name, data) VALUES (
  1, 'recipe2',
  '{
    "description":"a recipe to make things",
    "ingredients":[
      "chicken breast",
      "garlic"
    ],
    "steps":[
      "step 1",
      "step 2",
      "step 3"
    ]
   }');


INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe3', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe4', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe5', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe6', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe7', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe8', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe9', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe10', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe11', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe12', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe13', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe14', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe15', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe16', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe17', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe18', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe19', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe20', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe21', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe22', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe23', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe24', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe25', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe26', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe27', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe28', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe29', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe30', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe31', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe32', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe33', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe34', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe35', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe36', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe37', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe38', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe39', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe40', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe41', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe42', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe43', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe44', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe45', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe46', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe47', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe48', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe49', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe50', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe51', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe52', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');
INSERT INTO recipes (ownerId, name, data) VALUES (1, 'recipe53', '{ "description":"a recipe to make things", "ingredients":[ "chicken breast", "garlic" ], "steps":[ "step 1", "step 2", "step 3", "step 4", "step 5" ] }');

SELECT * FROM recipes;

INSERT INTO recipe_notes (recipeId, note) VALUES (50, 'Small note.');
INSERT INTO recipe_notes (recipeId, note) VALUES (50, 'Big long note that goes on for a lot of characters. This food is really good, you should make this again.');
INSERT INTO recipe_notes (recipeId, note) VALUES (10, 'only note on this recipe');

