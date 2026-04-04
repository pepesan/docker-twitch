db.createUser({
    user: "admin",
    pwd: "password_segura",
    roles: [ { role: "root", db: "admin" } ]
});

