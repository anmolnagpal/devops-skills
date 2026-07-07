// Fixture: no security headers, permissive CORS with credentials. Not a real service.
const express = require("express")
const cors = require("cors")

const app = express()

app.use(cors({ origin: "*", credentials: true }))

app.get("/api/account", (req, res) => {
  res.json({ id: req.session.userId })
})

app.listen(3000)
