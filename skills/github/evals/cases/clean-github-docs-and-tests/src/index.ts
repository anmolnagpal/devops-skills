export function priceOrder(lines: Array<{ qty: number; unit: number }>): number {
  return lines.reduce((total, l) => total + l.qty * l.unit, 0)
}
