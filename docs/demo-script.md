# Thesis Demo Script

This script provides a step-by-step walkthrough for demonstrating the QRollCall system's core features during the thesis presentation.

## Scenario: First Day of Class

### 1. Teacher Setup (Admin View)
1. **Login** as Admin.
2. **Create a Class**: "CS101: Introduction to Computer Science".
3. **Invite a Student**: Invite `student@test.com` (use their username if known).
4. **Create a Linked Event**:
   - Title: "Lecture 1: Orientation".
   - Select Class: "CS101".
   - Note the real-time Dashboard opening up.

### 2. Student Onboarding (Student View)
1. **Login** as a Student.
2. **Check Notifications**: See the invitation to join "CS101".
3. **Accept Invite**: Go to **My Classes** -> **Pending Invitations** and accept.
4. **View Joined Class**: Confirm "CS101" appears in the active list.

### 3. The Attendance Moment (Security Verification)
1. **Teacher**: Show the **Live Dashboard**. Note that the student is marked as **Absent** (roster-aware).
2. **Student**: Attempt to scan the QR code **outside the geofence** (simulate by walking away or using a mock location).
3. **Observation**: Student gets a "Rejected" message. Teacher dashboard updates to show **1 Rejected**.
4. **Student**: Move inside the geofence and scan again.
5. **Observation**: Student gets "Attendance Verified". Teacher dashboard updates to show **1 Present**.

### 4. Reporting (Final Audit)
1. **Teacher**: End the event (or let it expire).
2. **Export Report**: Go to **Reports** and generate an Event Report for "Lecture 1".
3. **Verification**: Show the roster-aware PDF/CSV where the student is correctly marked as **Present** with time and location metadata.
