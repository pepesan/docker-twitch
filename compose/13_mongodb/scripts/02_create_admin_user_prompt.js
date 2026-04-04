// asegurate de estar en admin
// meter la password por prompt

db.createUser({
    user: "admin2",
    pwd: passwordPrompt(),
    roles: [ { role: "root", db: "admin" } ]
});

