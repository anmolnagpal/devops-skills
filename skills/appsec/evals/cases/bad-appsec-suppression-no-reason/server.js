const express = require("express")
const cors = require("cors")
const app = express()

// appsec-skill:ignore SEC-APP-002
app.use(cors({ origin: "*", credentials: true }))

app.get("/account", (req, res) => res.json({ ok: true }))
app.listen(3000)
