# HUD Plugin Developer Guide

**Complete guide for building compatible HUD plugin endpoints**

## Quick Start (5 Minutes)

### Step 1: Choose Your Stack

Pick any language/framework that can serve HTTP/JSON:
- Node.js/Express ✅
- Python/Flask ✅
- Go ✅
- PHP ✅
- Ruby/Rails ✅
- Java/Spring ✅
- Any other!

### Step 2: Implement Two Endpoints

1. **Discovery**: `/plugins/discover` (tells the app what plugins you have)
2. **Data**: `/plugins/your-plugin` (returns the actual data)

### Step 3: Deploy & Test

Deploy to any HTTPS server and test with the HUD app!

---

## Core Concepts

### Plugin Architecture

```
┌─────────────────┐
│   HUD visionOS  │
│      App        │
└────────┬────────┘
         │
         │ 1. Discover plugins
         ▼
┌─────────────────┐
│ /plugins/       │
│   discover      │◄─── Returns list of available plugins
└────────┬────────┘
         │
         │ 2. Fetch data
         ▼
┌─────────────────┐
│ /plugins/       │
│   weather       │◄─── Returns formatted data
└─────────────────┘
         │
         │ 3. Collect & analyze
         ▼
┌─────────────────┐
│  Your Data      │
│  Sources        │
└─────────────────┘
```

### Data Flow

1. **User adds your plugin** by entering your base URL
2. **App calls** `/plugins/discover` to get available plugins
3. **User selects** which plugins to enable
4. **App periodically calls** data endpoints (every 30s - 5min)
5. **Data is displayed** in ornaments and widgets

---

## Implementation Checklist

### Required

- [ ] Discovery endpoint at `/plugins/discover`
- [ ] At least one data endpoint (e.g., `/plugins/mydata`)
- [ ] Return proper JSON structure
- [ ] Include `apiVersion: "1.0.0"`
- [ ] HTTPS in production
- [ ] Response time < 1 second

### Recommended

- [ ] API key authentication
- [ ] Rate limiting
- [ ] Error handling
- [ ] Caching
- [ ] Monitoring/logging
- [ ] Documentation

### Optional

- [ ] Multiple plugins per server
- [ ] Query parameters for customization
- [ ] Webhooks for real-time updates
- [ ] OAuth2 authentication

---

## Minimal Example (Node.js)

```javascript
const express = require('express');
const app = express();

// Discovery endpoint
app.get('/plugins/discover', (req, res) => {
  res.json({
    apiVersion: "1.0.0",
    plugins: [{
      metadata: {
        id: "com.yourcompany.yourplugin",
        name: "Your Plugin Name",
        version: "1.0.0",
        author: "Your Name",
        description: "What your plugin does",
        icon: "chart.bar.fill",
        categories: ["category"],
        refreshInterval: 60
      },
      endpoint: "/plugins/data",
      authentication: null,
      rateLimit: null,
      parameters: []
    }]
  });
});

// Data endpoint
app.get('/plugins/data', (req, res) => {
  // Your data collection logic here
  const value = 42; // Replace with real data
  
  res.json({
    apiVersion: "1.0.0",
    plugin: {
      id: "com.yourcompany.yourplugin",
      name: "Your Plugin Name",
      version: "1.0.0",
      author: "Your Name",
      description: "What your plugin does",
      icon: "chart.bar.fill",
      categories: ["category"],
      refreshInterval: 60
    },
    data: {
      value: { number: value },
      metrics: {
        unit: { string: "units" }
      },
      metadata: {},
      collectedAt: new Date().toISOString()
    },
    error: null,
    timestamp: new Date().toISOString()
  });
});

app.listen(3000);
```

---

## Data Collection Strategies

### 1. Poll External APIs

```javascript
async function collectWeatherData() {
  const response = await fetch('https://api.weather.com/...');
  const data = await response.json();
  return {
    value: { number: data.temperature },
    metrics: {
      temperature: { number: data.temperature },
      humidity: { integer: data.humidity },
      unit: { string: "°F" }
    },
    metadata: {
      location: data.location
    }
  };
}
```

### 2. Database Queries

```python
def collect_database_metrics():
    conn = psycopg2.connect(...)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM users")
    count = cursor.fetchone()[0]
    return {
        "value": {"integer": count},
        "metrics": {
            "totalUsers": {"integer": count},
            "unit": {"string": "users"}
        }
    }
```

### 3. System Metrics

```go
func collectSystemMetrics() DataPayload {
    var m runtime.MemStats
    runtime.ReadMemStats(&m)
    return DataPayload{
        Value: PluginValue{Number: float64(m.Alloc)},
        Metrics: map[string]PluginValue{
            "memory": {Number: float64(m.Alloc)},
            "unit": {String: "bytes"},
        },
    }
}
```

### 4. IoT Sensors

```python
def collect_sensor_data():
    temperature = read_temperature_sensor()
    humidity = read_humidity_sensor()
    return {
        "value": {"number": temperature},
        "metrics": {
            "temperature": {"number": temperature},
            "humidity": {"integer": humidity},
            "unit": {"string": "°C"}
        }
    }
```

---

## Authentication Patterns

### API Key (Recommended)

```javascript
app.get('/plugins/data', (req, res) => {
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== process.env.API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  // ... rest of handler
});
```

Discovery response:
```json
{
  "authentication": {
    "type": "apikey",
    "location": "header",
    "parameterName": "X-API-Key"
  }
}
```

### Bearer Token

```python
@app.route('/plugins/data')
def data():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"error": "Unauthorized"}), 401
    token = auth_header.split(' ')[1]
    if not verify_token(token):
        return jsonify({"error": "Invalid token"}), 401
    # ... rest of handler
```

---

## Error Handling

### Graceful Degradation

```javascript
app.get('/plugins/data', async (req, res) => {
  try {
    const data = await collectData();
    res.json({
      apiVersion: "1.0.0",
      plugin: { /* metadata */ },
      data: data,
      error: null,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.json({
      apiVersion: "1.0.0",
      plugin: { /* metadata */ },
      data: {
        value: { string: "N/A" },
        collectedAt: new Date().toISOString()
      },
      error: {
        code: "DATA_COLLECTION_FAILED",
        message: "Unable to collect data",
        details: error.message,
        retryable: true
      },
      timestamp: new Date().toISOString()
    });
  }
});
```

---

## Performance Optimization

### 1. Caching

```javascript
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 30 });

app.get('/plugins/data', (req, res) => {
  const cached = cache.get('data');
  if (cached) {
    return res.json(cached);
  }
  
  const data = collectExpensiveData();
  const response = formatResponse(data);
  cache.set('data', response);
  res.json(response);
});
```

### 2. Async Collection

```python
import asyncio

async def collect_all_metrics():
    results = await asyncio.gather(
        collect_metric_1(),
        collect_metric_2(),
        collect_metric_3(),
        return_exceptions=True
    )
    return combine_results(results)
```

### 3. Database Connection Pooling

```go
var db *sql.DB

func init() {
    db, _ = sql.Open("postgres", connStr)
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
}
```

---

## Testing Your Plugin

### 1. Manual Testing

```bash
# Test discovery
curl https://your-api.com/plugins/discover | jq .

# Test data endpoint
curl -H "X-API-Key: your-key" \
     https://your-api.com/plugins/data | jq .

# Check response time
time curl https://your-api.com/plugins/data
```

### 2. JSON Validation

```bash
# Validate JSON structure
curl https://your-api.com/plugins/data | \
  jq '.apiVersion, .plugin, .data, .timestamp' > /dev/null && \
  echo "✅ Valid structure" || \
  echo "❌ Invalid structure"
```

### 3. Load Testing

```bash
# Using Apache Bench
ab -n 100 -c 10 https://your-api.com/plugins/data

# Using wrk
wrk -t4 -c100 -d30s https://your-api.com/plugins/data
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Test all endpoints locally
- [ ] Validate JSON responses
- [ ] Check response times
- [ ] Test authentication
- [ ] Review error handling
- [ ] Add monitoring/logging

### Deployment

- [ ] Deploy to HTTPS endpoint
- [ ] Configure environment variables
- [ ] Set up SSL certificate
- [ ] Configure CORS if needed
- [ ] Enable rate limiting
- [ ] Set up monitoring

### Post-Deployment

- [ ] Test from HUD app
- [ ] Monitor error rates
- [ ] Check response times
- [ ] Verify data accuracy
- [ ] Update documentation

---

## Common Patterns

### Multi-Metric Plugin

```javascript
{
  "data": {
    "value": { "number": 42.5 },  // Primary value
    "metrics": {
      "metric1": { "number": 42.5 },
      "metric2": { "integer": 100 },
      "metric3": { "string": "active" },
      "unit": { "string": "%" }
    }
  }
}
```

### Time-Series Data

```javascript
{
  "data": {
    "value": { "number": 42.5 },
    "metadata": {
      "trend": "increasing",
      "change24h": "+5.2%",
      "peak24h": "48.3"
    }
  }
}
```

### Status Monitoring

```javascript
{
  "data": {
    "value": { "string": "operational" },
    "metrics": {
      "status": { "string": "operational" },
      "uptime": { "integer": 864000 },
      "latency": { "number": 45.2 }
    }
  }
}
```

---

## Icon Reference

Use any SF Symbol name:
- System: `cpu`, `memorychip`, `server.rack`
- Weather: `cloud.sun.fill`, `thermometer`
- Network: `wifi`, `antenna.radiowaves.left.and.right`
- Data: `chart.bar.fill`, `chart.line.uptrend.xyaxis`
- Status: `checkmark.circle.fill`, `exclamationmark.triangle.fill`

Browse all: https://developer.apple.com/sf-symbols/

---

## Support & Resources

- **Specification**: `PLUGIN_API_SPECIFICATION.md`
- **Examples**: `PLUGIN_EXAMPLES.md`
- **GitHub**: https://github.com/michyul/hdsup
- **Issues**: https://github.com/michyul/hdsup/issues

---

## FAQ

**Q: Can I host multiple plugins on one server?**  
A: Yes! Return multiple plugins in the discovery response.

**Q: How often will my endpoint be called?**  
A: Based on `refreshInterval` (30-300 seconds typically).

**Q: Do I need HTTPS?**  
A: Yes, for production. HTTP is OK for local testing.

**Q: Can I use webhooks for real-time updates?**  
A: Not yet, but it's on the roadmap!

**Q: What if my data source is slow?**  
A: Implement caching and return cached data while updating in background.

**Q: Can I charge for my plugin?**  
A: Yes, implement your own payment/licensing system.

---

## Example Plugin Ideas

- **Server Monitoring**: CPU, memory, disk usage
- **Website Analytics**: Visitors, page views
- **IoT Sensors**: Temperature, humidity, air quality
- **Crypto Prices**: Bitcoin, Ethereum prices
- **Stock Market**: Stock prices, indices
- **Social Media**: Follower counts, engagement
- **CI/CD Status**: Build status, deployment info
- **Database Metrics**: Query count, connections
- **API Metrics**: Request count, latency
- **Custom Business Metrics**: Sales, revenue, KPIs

Happy building! 🚀
