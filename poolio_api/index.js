const express = require("express");

const baseLogger = require("./logger");

const PORT = process.env.PORT || 8080;

const app = express();

app.get("/", (req, res) => {
  res.json({
    message: "app is responding",
  });
});

app.listen(PORT, () => {
  baseLogger.info(`App listening on port ${PORT}`);
});