const express = require("express");

const PORT = process.env.PORT || 8080;

const app = express();

app.get("/", (req, res) => {
  res.json({
    message: "app is responding",
  });
});

app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
});