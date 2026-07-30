// The whole service. No sibling test file, and nothing under test/ or __tests__/.
export function priceOrder(lines: Array<{ qty: number; unit: number }>): number {
  return lines.reduce((total, l) => total + l.qty * l.unit, 0)
}
