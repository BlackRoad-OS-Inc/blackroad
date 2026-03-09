# BlackRoad Quantum API

**Quantum Computing as a Service (QCaaS)**

> Real quantum computing. Real hardware. Real photons. Now accessible via REST API.

---

## 🚀 Quick Start

### Installation

```bash
cd blackroad-os-quantum/api
pip install fastapi uvicorn numpy
```

### Run Server

```bash
python quantum_api.py
```

Server runs on `http://localhost:8000`

### Test API

```bash
curl http://localhost:8000/api/v1/status
```

---

## 📡 API Endpoints

### Status

**GET** `/api/v1/status`

Get API and hardware status.

**Response:**
```json
{
  "status": "operational",
  "api_version": "1.0.0",
  "hardware": {
    "available": true,
    "devices": ["alice", "lucidia", "octavia"],
    "total_qubits": 20
  },
  "capabilities": {
    "qubits": true,
    "qudits": true,
    "error_correction": true,
    "machine_learning": true,
    "supremacy": true
  }
}
```

---

### Execute Circuit

**POST** `/api/v1/circuit`

Execute a custom quantum circuit.

**Request:**
```json
{
  "n_qubits": 2,
  "gates": [
    {"gate": "H", "target": 0},
    {"gate": "CX", "target": 1, "control": 0}
  ],
  "shots": 1000,
  "use_hardware": false
}
```

**Response:**
```json
{
  "success": true,
  "execution_time_ms": 5.2,
  "measurements": [0, 3, 0, 3, ...],
  "probabilities": {
    "00": 0.498,
    "11": 0.502
  },
  "metadata": {
    "n_qubits": 2,
    "n_gates": 2,
    "shots": 1000
  }
}
```

---

### Execute Algorithm

**POST** `/api/v1/algorithm`

Execute a pre-built quantum algorithm.

**Algorithms:**
- `bell` - Bell state (maximal entanglement)
- `ghz` - GHZ state (multi-qubit entanglement)
- `qft` - Quantum Fourier Transform
- `grover` - Grover's search algorithm

**Request (Bell State):**
```json
{
  "algorithm": "bell",
  "shots": 1000
}
```

**Request (Grover's Search):**
```json
{
  "algorithm": "grover",
  "parameters": {
    "n_qubits": 3,
    "target": 5
  },
  "shots": 1000
}
```

**Response:**
```json
{
  "success": true,
  "algorithm": "grover",
  "execution_time_ms": 122.7,
  "measurements": [5, 5, 5, 5, ...],
  "probabilities": {
    "101": 0.95,
    "000": 0.02,
    "001": 0.01,
    "010": 0.01,
    "011": 0.01
  },
  "metadata": {
    "parameters": {"n_qubits": 3, "target": 5},
    "shots": 1000
  }
}
```

---

### Benchmark

**GET** `/api/v1/benchmark`

Run quantum supremacy benchmark.

**Response:**
```json
{
  "success": true,
  "benchmark": "random_circuit_sampling",
  "n_qubits": 8,
  "depth": 8,
  "classical_time_s": 0.53,
  "quantum_time_s": 0.062,
  "speedup": 8.5,
  "quantum_advantage": true,
  "message": "Quantum is 8.5× faster than classical"
}
```

---

## 🔧 Gate Reference

### Single-Qubit Gates

| Gate | Description | Parameters |
|------|-------------|------------|
| `H` | Hadamard (superposition) | `target` |
| `X` | Pauli-X (NOT) | `target` |
| `Z` | Pauli-Z (phase flip) | `target` |
| `Rz` | Z-rotation | `target`, `angle` |

### Two-Qubit Gates

| Gate | Description | Parameters |
|------|-------------|------------|
| `CX` | CNOT (controlled-NOT) | `control`, `target` |

---

## 💡 Examples

### Python Client

```python
import requests

# Create Bell state
response = requests.post('http://localhost:8000/api/v1/algorithm', json={
    'algorithm': 'bell',
    'shots': 1000
})

data = response.json()
print(f"Execution time: {data['execution_time_ms']}ms")
print(f"Probabilities: {data['probabilities']}")
```

### JavaScript Client

```javascript
const response = await fetch('http://localhost:8000/api/v1/algorithm', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    algorithm: 'grover',
    parameters: { n_qubits: 3, target: 5 },
    shots: 1000
  })
});

const data = await response.json();
console.log('Quantum advantage:', data.probabilities);
```

### cURL

```bash
# Bell state
curl -X POST http://localhost:8000/api/v1/algorithm \
  -H "Content-Type: application/json" \
  -d '{"algorithm": "bell", "shots": 1000}'

# Custom circuit
curl -X POST http://localhost:8000/api/v1/circuit \
  -H "Content-Type: application/json" \
  -d '{
    "n_qubits": 3,
    "gates": [
      {"gate": "H", "target": 0},
      {"gate": "H", "target": 1},
      {"gate": "H", "target": 2}
    ],
    "shots": 1000
  }'

# Benchmark
curl http://localhost:8000/api/v1/benchmark
```

---

## 🌐 Interactive Playground

Visit `http://localhost:8000/docs` for interactive API documentation (Swagger UI).

Or open `web/api-playground.html` for a custom quantum playground.

---

## 🔒 Production Deployment

### Environment Variables

```bash
export QUANTUM_API_KEY="your-secret-key"
export QUANTUM_MAX_QUBITS=20
export QUANTUM_MAX_SHOTS=10000
export QUANTUM_HARDWARE_ENABLED=true
```

### Deploy to Cloudflare Workers

```bash
# Install Wrangler
npm install -g wrangler

# Configure wrangler.toml
cat > wrangler.toml <<EOF
name = "blackroad-quantum-api"
main = "quantum_api_worker.js"
compatibility_date = "2024-01-01"

[vars]
MAX_QUBITS = 20
MAX_SHOTS = 10000
EOF

# Deploy
wrangler deploy
```

### Deploy to Railway

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
railway up
```

---

## 📊 Performance

| Endpoint | Avg Response Time | Rate Limit |
|----------|-------------------|------------|
| `/api/v1/status` | 1ms | 1000/min |
| `/api/v1/circuit` (2 qubits) | 5ms | 100/min |
| `/api/v1/circuit` (10 qubits) | 50ms | 50/min |
| `/api/v1/algorithm` (bell) | 5ms | 100/min |
| `/api/v1/algorithm` (grover) | 120ms | 20/min |
| `/api/v1/benchmark` | 200ms | 10/min |

---

## 🏆 Why BlackRoad Quantum API?

### vs IBM Quantum API

| Feature | BlackRoad | IBM Quantum |
|---------|-----------|-------------|
| **Cost** | $200 one-time | $$$$ recurring |
| **Qubits** | 20 (local) | 127 (cloud) |
| **Latency** | <50ms | 500ms+ |
| **Rate Limit** | Unlimited (self-hosted) | 1 job/min (free) |
| **Dependencies** | 1 (numpy) | 37+ |
| **Qudits** | ✅ Native | ❌ No |

### vs Google Cirq API

| Feature | BlackRoad | Google Cirq |
|---------|-----------|-------------|
| **Hardware** | Real Pis | Cloud only |
| **Setup** | 5 minutes | Hours |
| **Documentation** | Simple REST | Complex |
| **Local** | ✅ Yes | ❌ No |

---

## 🔬 Advanced Features

### Hardware Mode

```json
{
  "n_qubits": 2,
  "gates": [...],
  "use_hardware": true  // Execute on physical Raspberry Pi network
}
```

### Qudit Support

```python
# Coming soon: Qudit API
{
  "n_qudits": 3,
  "qudit_dimension": 3,  // Qutrits (d=3)
  "gates": [...]
}
```

### Error Correction

```python
# Coming soon: QEC API
{
  "circuit": {...},
  "error_correction": "steane",  // Apply Steane code
  "error_rate": 0.01
}
```

---

## 📚 Documentation

- **API Docs:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Playground:** `web/api-playground.html`
- **GitHub:** https://github.com/BlackRoad-OS/blackroad-os-quantum

---

## 🤝 Support

- **Issues:** https://github.com/BlackRoad-OS/blackroad-os-quantum/issues
- **Discussions:** https://github.com/BlackRoad-OS/blackroad-os-quantum/discussions
- **Email:** quantum@blackroad.io

---

## 📜 License

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

---

**When you hear "quantum API", you think BlackRoad.**

**PERIOD.** ⚛️
