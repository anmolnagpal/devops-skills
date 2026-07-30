# One-file naming helper. Self-evident, so exclusion 10 applies and no README is due.
locals {
  name_prefix = "${var.client}-${var.environment}"
}
