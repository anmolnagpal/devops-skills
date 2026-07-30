import { priceOrder } from "./index"

test("sums quantity times unit price", () => {
  expect(priceOrder([{ qty: 2, unit: 350 }, { qty: 1, unit: 99 }])).toBe(799)
})

test("an empty order costs nothing", () => {
  expect(priceOrder([])).toBe(0)
})
