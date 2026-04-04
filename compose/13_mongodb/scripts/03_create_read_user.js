// asegurate de estar en admin
// meter la password por prompt
use('analytics');

db.createUser({
    user: "analize",
    pwd: passwordPrompt(),
    roles: [ { role: "read", db: "analytics" } ]
});

