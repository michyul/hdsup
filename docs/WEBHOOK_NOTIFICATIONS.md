# Webhook Notifications System

## Overview

The HUD app includes a built-in webhook notification system that allows external applications to push notifications that appear in your visionOS space with customizable presentation styles.

## Key Features

- **Push Notifications**: Real-time notification delivery via webhooks
- **Configurable Presentation**: Route notifications to different HUD displays based on source, type, or priority
- **Spatial Positioning**: Place notifications at specific locations in your environment
- **Multiple Styles**: Banner, ornament, fixed widget, spatial object, immersive alert
- **Priority Levels**: Low, normal, high, urgent
- **Interactive Actions**: Notifications can include actionable buttons
- **Auto-dismiss**: Configurable automatic dismissal

## Webhook Endpoint

Once the HUD app is running, the webhook server listens on:

```
POST http://<your-vision-pro-ip>:8080/webhook
```

You can find your exact webhook URL in the app settings.

## Notification Format

### Request

```http
POST /webhook HTTP/1.1
Content-Type: application/json

{
  "id": "unique-notification-id",
  "source": {
    "id": "com.apple.messages",
    "name": "iMessage",
    "icon": "message.fill",
    "category": "communication"
  },
  "type": "message",
  "content": {
    "title": "John Doe",
    "subtitle": "New message",
    "body": "Hey, are you free tonight?",
    "imageURL": null,
    "soundName": "default",
    "badge": 1
  },
  "priority": "normal",
  "timestamp": "2026-03-25T14:30:00Z",
  "expiresAt": "2026-03-25T15:30:00Z",
  "metadata": {
    "conversation_id": "abc123"
  },
  "actions": [
    {
      "id": "reply",
      "title": "Reply",
      "type": "reply",
      "url": null,
      "destructive": false
    },
    {
      "id": "dismiss",
      "title": "Dismiss",
      "type": "dismiss",
      "url": null,
      "destructive": false
    }
  ]
}
```

### Response

```json
{
  "status": "received"
}
```

## Field Reference

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier for this notification |
| `source` | object | Information about the sending application |
| `source.id` | string | Unique identifier for the source app (reverse domain) |
| `source.name` | string | Display name of the source app |
| `source.category` | string | Category (e.g., "communication", "email", "social") |
| `type` | enum | Type: message, email, alert, reminder, event, call, custom |
| `content` | object | Notification content |
| `content.title` | string | Main title (required) |
| `priority` | enum | Priority level: low, normal, high, urgent |
| `timestamp` | string | ISO 8601 timestamp when notification was created |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `source.icon` | string | SF Symbol name or icon URL |
| `content.subtitle` | string | Secondary text |
| `content.body` | string | Full message body |
| `content.imageURL` | string | URL to notification image |
| `content.soundName` | string | Sound to play |
| `content.badge` | integer | Badge number |
| `expiresAt` | string | ISO 8601 timestamp when notification expires |
| `metadata` | object | Custom key-value pairs |
| `actions` | array | Interactive actions |

### Action Object

```json
{
  "id": "action-id",
  "title": "Action Title",
  "type": "openURL|reply|dismiss|custom",
  "url": "https://example.com",
  "destructive": false
}
```

## Notification Types

- `message` - Chat/messaging notifications
- `email` - Email notifications
- `alert` - System alerts
- `reminder` - Reminders and to-dos
- `event` - Calendar events
- `call` - Incoming calls
- `custom` - Custom notification types

## Priority Levels

- `low` - Non-urgent, can be grouped
- `normal` - Standard priority (default)
- `high` - Important, deserves attention
- `urgent` - Critical, requires immediate action

## Presentation Styles

Users configure how notifications appear based on routing rules:

### 1. Banner
- Quick, temporary notification at top of view
- Auto-dismisses after 5 seconds (default)
- Minimal interruption

### 2. Ornament
- Floating UI that follows the view
- More detailed than banner
- Supports actions
- Configurable auto-dismiss

### 3. Fixed Widget
- Stays at a fixed location in space
- Ideal for persistent notifications (e.g., email)
- Does not auto-dismiss by default
- Can pin to walls or surfaces

### 4. Spatial Object
- Appears at a specific location in 3D space
- Can track physical objects
- Example: iMessage notifications appearing over your phone

### 5. Immersive Alert
- Full-screen, high-priority alert
- Darkens background
- Requires explicit dismissal
- Used for urgent notifications

### 6. Badge
- Minimal indicator on existing UI elements
- Low interruption
- Future feature

## Routing Rules

Users can create routing rules to control how notifications appear:

```swift
// Example: iMessage notifications appear near phone
{
  "name": "iMessage",
  "sourcePattern": "^com.apple.messages",
  "typeFilter": "message",
  "presentationStyle": "spatialObject",
  "spatialConfig": {
    "position": "tracked",
    "anchorType": "object",
    "offset": {"x": 0, "y": 0.2, "z": 0}
  }
}

// Example: Email as fixed wall widget
{
  "name": "Email",
  "typeFilter": "email",
  "presentationStyle": "fixedWidget",
  "spatialConfig": {
    "position": "fixed",
    "anchorType": "plane",
    "offset": {"x": 1.5, "y": 1.5, "z": -2}
  }
}

// Example: Urgent alerts as immersive
{
  "name": "Urgent",
  "priorityFilter": "urgent",
  "presentationStyle": "immersiveAlert"
}
```

## Example Implementations

### Node.js Example

```javascript
const axios = require('axios');

async function sendNotification(webhookURL, notification) {
  try {
    const response = await axios.post(webhookURL, {
      id: Date.now().toString(),
      source: {
        id: "com.myapp.notifications",
        name: "My App",
        icon: "bell.fill",
        category: "general"
      },
      type: "custom",
      content: {
        title: "Hello from My App!",
        subtitle: "This is a test notification",
        body: "Testing the webhook notification system"
      },
      priority: "normal",
      timestamp: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 60000).toISOString(),
      actions: [
        {
          id: "view",
          title: "View",
          type: "openURL",
          url: "https://example.com",
          destructive: false
        }
      ]
    });
    console.log('Notification sent:', response.data);
  } catch (error) {
    console.error('Error sending notification:', error.message);
  }
}

// Usage
const webhookURL = "http://192.168.1.100:8080/webhook";
sendNotification(webhookURL, notification);
```

### Python Example

```python
import requests
from datetime import datetime, timedelta

def send_notification(webhook_url, notification):
    try:
        response = requests.post(webhook_url, json={
            "id": str(int(datetime.now().timestamp())),
            "source": {
                "id": "com.myapp.notifications",
                "name": "My App",
                "icon": "bell.fill",
                "category": "general"
            },
            "type": "custom",
            "content": {
                "title": "Hello from My App!",
                "subtitle": "This is a test notification",
                "body": "Testing the webhook notification system"
            },
            "priority": "normal",
            "timestamp": datetime.utcnow().isoformat() + 'Z',
            "expiresAt": (datetime.utcnow() + timedelta(minutes=1)).isoformat() + 'Z',
            "actions": [
                {
                    "id": "view",
                    "title": "View",
                    "type": "openURL",
                    "url": "https://example.com",
                    "destructive": False
                }
            ]
        })
        print(f"Notification sent: {response.json()}")
    except Exception as e:
        print(f"Error sending notification: {e}")

# Usage
webhook_url = "http://192.168.1.100:8080/webhook"
send_notification(webhook_url)
```

### cURL Example

```bash
curl -X POST http://192.168.1.100:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-123",
    "source": {
      "id": "com.test.app",
      "name": "Test App",
      "icon": "star.fill",
      "category": "test"
    },
    "type": "custom",
    "content": {
      "title": "Test Notification",
      "subtitle": "From cURL",
      "body": "This is a test notification sent via cURL"
    },
    "priority": "normal",
    "timestamp": "2026-03-25T14:30:00Z"
  }'
```

## Use Cases

### 1. iMessage Integration
- Notifications appear as spatial objects near your phone
- Quick reply actions
- Auto-dismiss after 30 seconds

### 2. Email Notifications
- Fixed widget on wall
- Shows unread count
- Persistent until dismissed
- Preview of email content

### 3. Calendar Reminders
- Banner notification 15 minutes before event
- Shows event details
- Snooze and view actions

### 4. Smart Home Alerts
- Doorbell notifications appear near front door
- Security camera alerts
- Urgent alerts use immersive style

### 5. Monitoring Alerts
- Server down alerts as urgent immersive
- Performance warnings as high priority banners
- Status updates as low priority badges

## Best Practices

1. **Use appropriate priorities**: Reserve urgent for truly critical notifications
2. **Provide actions**: Make notifications actionable when possible
3. **Set expiration**: Use `expiresAt` for time-sensitive notifications
4. **Include metadata**: Add context for better routing and filtering
5. **Use clear titles**: First line should convey the essence
6. **Respect auto-dismiss**: Let users configure dismissal times
7. **Test different styles**: See how your notifications look in each style

## Security Considerations

- The webhook server runs on the local network only
- No authentication required (local trusted network)
- Consider firewall rules for additional security
- HTTPS support planned for future versions

## Troubleshooting

**Notifications not appearing?**
- Check that webhook server is running in app
- Verify your Vision Pro's IP address
- Ensure you're on the same network
- Check that routing rules match your notification

**Wrong presentation style?**
- Review routing rules in app settings
- Rules are matched in order (first match wins)
- Check source ID pattern matching

**Actions not working?**
- Verify action type is supported
- Check URL format for openURL actions
- Review app logs for errors

## Future Enhancements

- HTTPS support with authentication
- Webhook authentication tokens
- Push notification service integration
- Rich media (images, videos)
- Custom sounds
- Grouping and threading
- Reply functionality
- Delivery receipts and read status

## Support

For issues or questions:
- GitHub: https://github.com/michyul/hdsup/issues
- Documentation: https://github.com/michyul/hdsup/blob/main/README.md
