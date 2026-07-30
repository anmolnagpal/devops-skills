# clean-finops-waivers-honored

Nothing may fire. Two waivers, both with reasons that state a real trade-off rather
than a shrug, so both are honored and neither raises `META-SUP-001`.

The reasons are deliberately of the kind the skill's own exclusions name: Multi-AZ in
non-prod kept for load-test parity (exclusion 2) and a shared dev cluster that is
actually in use overnight (exclusion 1). A waiver that restates the rule ID back at
you ("COST-DB-001 accepted") is not this case, and would be worth reporting.
