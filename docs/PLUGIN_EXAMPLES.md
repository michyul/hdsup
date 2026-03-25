# Plugin Implementation Examples

This document provides complete, working examples of HUD plugin servers in multiple programming languages.

## Table of Contents

1. [Node.js / Express](#nodejs--express)
2. [Python / Flask](#python--flask)
3. [Go](#go)
4. [PHP](#php)
5. [Deployment Instructions](#deployment)

---

## Node.js / Express

### Installation

```bash
npm init -y
npm install express cors
```

### Complete Server (`server.js`)

```javascript
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Discovery endpoint
app.get('/plugins/discover', (req, res) => {
  res.json({
    apiVersion: "1.0.0",
    plugins: [
      {
        metadata: {
          id: "com.example.system",
          name: "System Monitor",
          version: "1.0.0",
          author: "Your Name",
          description: "Server system metrics",
          icon: "cpu",
          categories: ["system", "monitoring"],
          refreshInterval: 30,
          homepage: null
        },
        endpoint: "/plugins/system",
        authentication: {
          type: "apikey",
          location: "header",
          parameterName: "X-API-Key"
        },
        rateLimit: {
          maxRequests: 60,
          periodSeconds: 60
        },
        parameters: []
      }
    ]
  });
});

// Data endpoint
app.get('/plugins/system', (req, res) => {
  // Simple API key check
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== process.env.API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  // Get system data (simplified - use proper system metrics in production)
  const cpuUsage = Math.random() * 100;
  const memoryUsage = Math.random() * 100;
  const uptime = process.uptime();

  res.json({
    apiVersion: "1.0.0",
    plugin: {
      id: "com.example.system",
      name: "System Monitor",
      version: "1.0.0",
      author: "Your Name",
      description: "Server system metrics",
      icon: "cpu",
      categories: ["system"],
      refreshInterval: 30
    },
    data: {
      value: { number: Math.round(cpuUsage * 10) / 10 },
      metrics: {
        cpu: { number: Math.round(cpuUsage * 10) / 10 },
        memory: { number: Math.round(memoryUsage * 10) / 10 },
        uptime: { integer: Math.floor(uptime) },
        unit: { string: "%" }
      },
      metadata: {
        hostname: require('os').hostname(),
        platform: process.platform,
        nodeVersion: process.version
      },
      collectedAt: new Date().toISOString(),
      source: {
        name: "Node.js Process",
        type: "api",
        location: "local",
        freshnessSeconds: 1
      }
    },
    error: null,
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`Plugin server running on port ${PORT}`);
  console.log(`Discovery: http://localhost:${PORT}/plugins/discover`);
  console.log(`Data: http://localhost:${PORT}/plugins/system`);
});
```

### Run

```bash
export API_KEY="your-secret-key"
node server.js
```

### Test

```bash
curl http://localhost:3000/plugins/discover
curl -H "X-API-Key: your-secret-key" http://localhost:3000/plugins/system
```

---

## Python / Flask

### Installation

```bash
pip install flask flask-cors
```

### Complete Server (`app.py`)

```python
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime, timezone
import os
import psutil  # pip install psutil for real system metrics

app = Flask(__name__)
CORS(app)

API_KEY = os.environ.get('API_KEY', 'your-secret-key')

@app.route('/plugins/discover', methods=['GET'])
def discover():
    return jsonify({
        "apiVersion": "1.0.0",
        "plugins": [
            {
                "metadata": {
                    "id": "com.example.system.python",
                    "name": "System Monitor (Python)",
                    "version": "1.0.0",
                    "author": "Your Name",
                    "description": "Server system metrics via Python",
                    "icon": "memorychip",
                    "categories": ["system", "monitoring"],
                    "refreshInterval": 30,
                    "homepage": None
                },
                "endpoint": "/plugins/system",
                "authentication": {
                    "type": "apikey",
                    "location": "header",
                    "parameterName": "X-API-Key"
                },
                "rateLimit": {
                    "maxRequests": 60,
                    "periodSeconds": 60
                },
                "parameters": []
            }
        ]
    })

@app.route('/plugins/system', methods=['GET'])
def system_data():
    # Check API key
    api_key = request.headers.get('X-API-Key')
    if api_key != API_KEY:
        return jsonify({"error": "Unauthorized"}), 401
    
    # Get real system metrics
    cpu_percent = psutil.cpu_percent(interval=0.1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    return jsonify({
        "apiVersion": "1.0.0",
        "plugin": {
            "id": "com.example.system.python",
            "name": "System Monitor (Python)",
            "version": "1.0.0",
            "author": "Your Name",
            "description": "Server system metrics via Python",
            "icon": "memorychip",
            "categories": ["system"],
            "refreshInterval": 30
        },
        "data": {
            "value": {"number": round(cpu_percent, 1)},
            "metrics": {
                "cpu": {"number": round(cpu_percent, 1)},
                "memory": {"number": round(memory.percent, 1)},
                "disk": {"number": round(disk.percent, 1)},
                "unit": {"string": "%"}
            },
            "metadata": {
                "hostname": os.uname().nodename,
                "platform": os.uname().sysname,
                "cores": str(psutil.cpu_count())
            },
            "collectedAt": datetime.now(timezone.utc).isoformat(),
            "source": {
                "name": "psutil",
                "type": "system",
                "location": "local",
                "freshnessSeconds": 1
            }
        },
        "error": None,
        "timestamp": datetime.now(timezone.utc).isoformat()
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"Plugin server running on port {port}")
    print(f"Discovery: http://localhost:{port}/plugins/discover")
    print(f"Data: http://localhost:{port}/plugins/system")
    app.run(host='0.0.0.0', port=port, debug=True)
```

### Run

```bash
export API_KEY="your-secret-key"
python app.py
```

---

## Go

### Complete Server (`main.go`)

```go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"
)

type PluginValue struct {
	String  *string  `json:"string,omitempty"`
	Number  *float64 `json:"number,omitempty"`
	Integer *int     `json:"integer,omitempty"`
}

type DiscoveryResponse struct {
	APIVersion string           `json:"apiVersion"`
	Plugins    []PluginManifest `json:"plugins"`
}

type PluginManifest struct {
	Metadata       PluginMetadata      `json:"metadata"`
	Endpoint       string              `json:"endpoint"`
	Authentication *AuthRequirement    `json:"authentication,omitempty"`
	RateLimit      *RateLimit          `json:"rateLimit,omitempty"`
}

type PluginMetadata struct {
	ID              string   `json:"id"`
	Name            string   `json:"name"`
	Version         string   `json:"version"`
	Author          string   `json:"author"`
	Description     string   `json:"description"`
	Icon            string   `json:"icon"`
	Categories      []string `json:"categories"`
	RefreshInterval int      `json:"refreshInterval"`
}

type AuthRequirement struct {
	Type          string  `json:"type"`
	Location      string  `json:"location"`
	ParameterName *string `json:"parameterName,omitempty"`
}

type RateLimit struct {
	MaxRequests   int `json:"maxRequests"`
	PeriodSeconds int `json:"periodSeconds"`
}

type DataResponse struct {
	APIVersion string         `json:"apiVersion"`
	Plugin     PluginMetadata `json:"plugin"`
	Data       DataPayload    `json:"data"`
	Error      interface{}    `json:"error"`
	Timestamp  string         `json:"timestamp"`
}

type DataPayload struct {
	Value       PluginValue            `json:"value"`
	Metrics     map[string]PluginValue `json:"metrics,omitempty"`
	Metadata    map[string]string      `json:"metadata,omitempty"`
	CollectedAt string                 `json:"collectedAt"`
}

var apiKey = os.Getenv("API_KEY")

func main() {
	if apiKey == "" {
		apiKey = "your-secret-key"
	}

	http.HandleFunc("/plugins/discover", handleDiscover)
	http.HandleFunc("/plugins/system", handleSystemData)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Plugin server running on port %s", port)
	log.Printf("Discovery: http://localhost:%s/plugins/discover", port)
	log.Printf("Data: http://localhost:%s/plugins/system", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func handleDiscover(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	paramName := "X-API-Key"
	response := DiscoveryResponse{
		APIVersion: "1.0.0",
		Plugins: []PluginManifest{
			{
				Metadata: PluginMetadata{
					ID:              "com.example.system.go",
					Name:            "System Monitor (Go)",
					Version:         "1.0.0",
					Author:          "Your Name",
					Description:     "Server system metrics via Go",
					Icon:            "server.rack",
					Categories:      []string{"system", "monitoring"},
					RefreshInterval: 30,
				},
				Endpoint: "/plugins/system",
				Authentication: &AuthRequirement{
					Type:          "apikey",
					Location:      "header",
					ParameterName: &paramName,
				},
			},
		},
	}

	json.NewEncoder(w).Encode(response)
}

func handleSystemData(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Check API key
	if r.Header.Get("X-API-Key") != apiKey {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]string{"error": "Unauthorized"})
		return
	}

	// Get system metrics
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	goroutines := float64(runtime.NumGoroutine())
	numCPU := runtime.NumCPU()
	
	response := DataResponse{
		APIVersion: "1.0.0",
		Plugin: PluginMetadata{
			ID:              "com.example.system.go",
			Name:            "System Monitor (Go)",
			Version:         "1.0.0",
			Author:          "Your Name",
			Description:     "Server system metrics via Go",
			Icon:            "server.rack",
			Categories:      []string{"system"},
			RefreshInterval: 30,
		},
		Data: DataPayload{
			Value: PluginValue{Number: &goroutines},
			Metrics: map[string]PluginValue{
				"goroutines": {Number: &goroutines},
				"cpus":       {Integer: &numCPU},
			},
			Metadata: map[string]string{
				"goVersion": runtime.Version(),
				"os":        runtime.GOOS,
				"arch":      runtime.GOARCH,
			},
			CollectedAt: time.Now().UTC().Format(time.RFC3339),
		},
		Error:     nil,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	json.NewEncoder(w).Encode(response)
}
```

### Run

```bash
export API_KEY="your-secret-key"
go run main.go
```

---

## Deployment

### Docker

Create `Dockerfile`:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

Build and run:

```bash
docker build -t hud-plugin .
docker run -p 3000:3000 -e API_KEY=your-secret-key hud-plugin
```

### Cloud Deployment

- **Vercel**: Deploy Node.js example directly
- **Heroku**: Push any example with Procfile
- **AWS Lambda**: Use serverless framework
- **Google Cloud Run**: Deploy Docker container

---

## Next Steps

1. Choose your preferred language/framework
2. Implement data collection logic
3. Add proper authentication
4. Deploy to HTTPS endpoint
5. Test with HUD app
6. Share your plugin!
