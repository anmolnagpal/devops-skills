package internal

import (
	"encoding/json"
	"net/http"
	"time"
)

// checkout-api calls ledger-api over HTTP on every settlement. Two processes,
// one user request, and no trace context propagated across the boundary: no
// OTel SDK, no traceparent header, no request ID.
type LedgerClient struct {
	baseURL string
	http    *http.Client
}

func NewLedgerClient(baseURL string) *LedgerClient {
	return &LedgerClient{baseURL: baseURL, http: &http.Client{Timeout: 5 * time.Second}}
}

func (c *LedgerClient) Settle(orderID string, amount int64) error {
	body, _ := json.Marshal(map[string]any{"order_id": orderID, "amount": amount})
	req, err := http.NewRequest(http.MethodPost, c.baseURL+"/settle", bytesReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return nil
}
