// asegurate de estar en admin
// meter la password por prompt
use('analytics');

db.users.insertMany([
    { name: "Ana", age: 30 },
    { name: "Luis", age: 25 }
]);

