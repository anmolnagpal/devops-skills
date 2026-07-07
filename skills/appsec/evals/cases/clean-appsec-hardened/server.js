// Fixture: hardened headers, scoped CORS, patched dependency. Should produce ZERO findings.
const express = require("express")
const helmet = require("helmet")
const cors = require("cors")

const app = express()

app.use(helmet())
app.use(
  cors({
    origin: ["https://app.acme.example"],
    credentials: true,
  })
)

app.get("/api/account", (req, res) => {
  res.json({ id: req.session.userId })
})

app.listen(3000)
