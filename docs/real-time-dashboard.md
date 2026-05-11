# Real-Time Attendance Dashboard

## Current Implementation: Roster-Aware Polling

The QRollCall "Live" dashboard provides real-time visibility into an ongoing attendance event using a **Client-Side Polling** strategy.

### How it works
1. **Roster-Aware Backend**: The `get_live_attendance_snapshot` endpoint identifies every student enrolled in the associated ClassRoom.
2. **State Categorization**: Every student is mapped to one of three states:
   - **Present**: Verified scan within geofence and time window.
   - **Rejected**: Attempted scan that failed security checks.
   - **Absent**: Enrolled student who has not attempted a scan.
3. **10-Second Pulse**: The Flutter application executes a silent refresh of this snapshot every 10 seconds while the dashboard is active.

### Efficiency & Scalability
- **Polling vs WebSockets**: Polling was chosen for the MVP due to its stateless nature and high reliability in intermittent mobile network conditions.
- **Resource Usage**: Snapshot joins are optimized. For a typical class of 50-100 students, the payload is < 50KB.
- **Network Overhead**: At 10s intervals, 10 active admins would generate only 60 requests per minute, which is negligible for the FastAPI backend.

### Technical Limitations
- **Latency**: There is a maximum "freshness gap" of 10 seconds. An attendance scan may take up to 10 seconds to appear on an observer's screen.
- **No Push**: The server cannot "push" an update to the client; the client must ask.
- **Battery/Data**: Prolonged active observation on mobile will consume more data and battery than a push-based system (SSE/WS).

## Future Upgrade: SSE / WebSockets
For larger deployments (>500 concurrent students per event), we recommend transitioning to:
1. **Server-Sent Events (SSE)**: Unidirectional push for attendance updates.
2. **WebSockets**: Bidirectional communication if manual intervention features are added.
