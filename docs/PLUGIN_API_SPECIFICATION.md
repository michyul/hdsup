# HUD Plugin API Specification v1.0

This document defines the standard API specification for building compatible plugin endpoints for the HUD visionOS application.

## Table of Contents

1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Data Structures](#data-structures)
4. [Authentication](#authentication)
5. [Best Practices](#best-practices)
6. [Example Implementations](#example-implementations)
7. [Testing](#testing)

## Overview

The HUD Plugin API allows external services to provide data that can be displayed in the visionOS HUD application through ornaments and widgets. Plugins can be discovered dynamically and configured by users.

### Key Concepts

- **Plugin Server**: An HTTP(S) server that implements the plugin API specification
- **Discovery Endpoint**: Standard endpoint for announcing available plugins
- **Data Endpoint**: Plugin-specific endpoint that returns formatted data
- **API Version**: Semantic versioning for compatibility (currently `1.0.0`)

### Design Principles

1. **Stateless**: Each request is independent
2. **Simple**: Easy to implement in any language/framework
3. **Secure**: Support for multiple authentication methods
4. **Extensible**: Forward-compatible design

## API Endpoints

### 1. Discovery Endpoint (Required)

**Endpoint**: `/plugins/discover`  
**Method**: `GET`  
**Description**: Returns a list of available plugins at this server

#### Request

```http
GET /plugins/discover HTTP/1.1
Host: api.example.com
Accept: application/json
User-Agent: HUDApp/1.0
```

#### Response

```json
{
  "apiVersion": "1.0.0",
  "plugins": [
    {
      "metadata": {
        "id": "com.example.weather",
        "name": "Weather Monitor",
        "version": "1.2.0",
        "author": "Example Corp",
        "description": "Real-time weather data",
        "icon": "cloud.sun.fill",
        "categories": ["weather", "environment"],
        "refreshInterval": 300,
        "homepage": "https://example.com/weather-plugin"
      },
      "endpoint": "/plugins/weather",
      "authentication": {
        "type": "apikey",
        "location": "header",
        "parameterName": "X-API-Key"
      },
      "rateLimit": {
        "maxRequests": 100,
        "periodSeconds": 3600
      },
      "parameters": [
        {
          "name": "location",
          "type": "string",
          "required": false,
          "defaultValue": "auto",
          "description": "Location for weather data",
          "allowedValues": null
        }
      ]
    }
  ]
}
```

### 2. Plugin Data Endpoint (Required)

**Endpoint**: Plugin-specific (e.g., `/plugins/weather`)  
**Method**: `GET`  
**Description**: Returns current data for this plugin

#### Response

```json
{
  "apiVersion": "1.0.0",
  "plugin": {
    "id": "com.example.weather",
    "name": "Weather Monitor",
    "version": "1.2.0",
    "author": "Example Corp",
    "description": "Real-time weather data",
    "icon": "cloud.sun.fill",
    "categories": ["weather"],
    "refreshInterval": 300
  },
  "data": {
    "value": {
      "number": 22.5
    },
    "metrics": {
      "temperature": { "number": 22.5 },
      "humidity": { "integer": 65 },
      "condition": { "string": "Partly Cloudy" },
      "unit": { "string": "°C" }
    },
    "metadata": {
      "location": "San Francisco, CA"
    },
    "collectedAt": "2026-03-25T14:30:00Z"
  },
  "error": null,
  "timestamp": "2026-03-25T14:30:05Z"
}
```

## Testing

### Test Checklist

- [ ] Discovery endpoint returns valid JSON
- [ ] All required fields are present
- [ ] Data endpoint returns valid JSON
- [ ] Response time < 1 second
- [ ] HTTPS certificate is valid
- [ ] Authentication works correctly

See full specification in the repository documentation.
