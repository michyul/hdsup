# HUD Plugin System - Quick Start Guide

## For HUD App Users

### Adding a Plugin

1. Launch the HUD app on your Vision Pro
2. Click **"Manage Plugins"** button
3. Click **"Add Plugin"**
4. Enter the plugin server URL (e.g., `https://my-plugin.com`)
5. Click **"Discover Plugins"**
6. Select plugins to add
7. Configure authentication if needed
8. Enable/disable as desired

Plugins will automatically update based on their refresh interval.

---

## For Plugin Developers

### Minimal Working Example (60 seconds)

**1. Create `server.js`:**

```javascript
const express = require('express');
const app = express();

app.get('/plugins/discover', (req, res) => {
  res.json({
    apiVersion: "1.0.0",
    plugins: [{
      metadata: {
        id: "com.example.hello",
        name: "Hello World",
        version: "1.0.0",
        author: "You",
        description: "Simple example",
        icon: "star.fill",
        categories: ["example"],
        refreshInterval: 60
      },
      endpoint: "/plugins/data",
      authentication: null
    }]
  });
});

app.get('/plugins/data', (req, res) => {
  res.json({
    apiVersion: "1.0.0",
    plugin: {
      id: "com.example.hello",
      name: "Hello World",
      version: "1.0.0",
      author: "You",
      description: "Simple example",
      icon: "star.fill",
      categories: ["example"],
      refreshInterval: 60
    },
    data: {
      value: { number: 42 },
      metrics: {
        message: { string: "Hello HUD!" },
        unit: { string: "items" }
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

**2. Run:**
```bash
npm install express
node server.js
```

**3. Test:**
```bash
curl http://localhost:3000/plugins/discover
curl http://localhost:3000/plugins/data
```

**4. Deploy to HTTPS and add to HUD app!**

---

## API Specification Summary

### Required Endpoints

1. **Discovery**: `GET /plugins/discover`
   - Returns list of available plugins
   - Must include `apiVersion` and `plugins` array

2. **Data**: `GET /plugins/{your-plugin-name}`
   - Returns current data
   - Must include `apiVersion`, `plugin`, `data`, `timestamp`

### Data Value Types

```javascript
{ "string": "text" }
{ "number": 42.5 }
{ "integer": 100 }
{ "boolean": true }
{ "array": ["a", "b", "c"] }
```

### Authentication

```javascript
// No auth
"authentication": null

// API Key
"authentication": {
  "type": "apikey",
  "location": "header",
  "parameterName": "X-API-Key"
}

// Bearer Token
"authentication": {
  "type": "bearer",
  "location": "header"
}
```

---

## Plugin Ideas

- **Server Monitoring**: CPU, RAM, disk space
- **Weather**: Temperature, conditions
- **Crypto Prices**: Bitcoin, Ethereum
- **Stock Prices**: Real-time market data
- **IoT Sensors**: Temperature, humidity
- **Website Analytics**: Visitor count, page views
- **Social Media**: Follower count, engagement
- **CI/CD Status**: Build status, deployments
- **Database Metrics**: Connections, query count
- **Custom Business KPIs**: Sales, revenue, etc.

---

## Full Documentation

- **API Specification**: `docs/PLUGIN_API_SPECIFICATION.md`
- **Implementation Examples**: `docs/PLUGIN_EXAMPLES.md`
- **Developer Guide**: `docs/DEVELOPER_GUIDE.md`

---

## Support

- **GitHub**: https://github.com/michyul/hdsup
- **Issues**: https://github.com/michyul/hdsup/issues

---

## Testing Your Plugin

```bash
# Validate JSON structure
curl https://your-plugin.com/plugins/discover | jq .
curl https://your-plugin.com/plugins/data | jq .

# Check required fields
curl https://your-plugin.com/plugins/data | \
  jq '.apiVersion, .plugin, .data, .timestamp'

# Test response time
time curl https://your-plugin.com/plugins/data
```

---

## Deployment Options

- **Vercel**: Zero-config Node.js deployment
- **Heroku**: Simple git push deployment
- **AWS Lambda**: Serverless functions
- **Google Cloud Run**: Container deployment
- **DigitalOcean**: Traditional hosting
- **Your own server**: Any HTTP(S) server works!

**Important**: Must use HTTPS in production (HTTP OK for local testing)

---

Happy building! 🚀
