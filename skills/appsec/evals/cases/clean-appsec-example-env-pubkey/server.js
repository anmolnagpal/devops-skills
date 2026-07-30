const express = require("express")
const helmet = require("helmet")
const cors = require("cors")
const app = express()

app.use(helmet())
app.use(cors({ origin: ["https://app.acme.com"], credentials: true }))

app.get("/orders", (req, res) => res.json({ ok: true }))
app.listen(3000)
