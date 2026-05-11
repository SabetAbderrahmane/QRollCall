# Class Management Guide

QRollCall allows instructors to organize students into formal Classes (Courses) to streamline attendance tracking and reporting.

## For Teachers/Admins

### 1. Creating a Class
- Navigate to **Manage Classes** from the Admin Dashboard.
- Tap **Create New Class**.
- Define the class name, description, and optional location bounds.
- A unique **Class Code** is generated for internal tracking.

### 2. Inviting Students
- Open a Class from your list.
- Use the **Invite** button to send invitations by **Email** or **Username**.
- Students will receive an in-app notification to Accept or Decline.
- You can track pending invitations in the **Invitations** tab.

### 3. Linking Events to Classes
- When creating a new Event, you can now select a **Class** to link it to.
- Linking an event ensures that only enrolled students can scan (unless configured otherwise).
- It also enables **Roster-Aware Reporting**.

## For Students

### 1. Joining a Class
- You will receive a notification if a teacher invites you.
- Navigate to **My Classes** and check **Pending Invitations**.
- Once Accepted, you are part of the class roster.

### 2. Class Overview
- View your joined classes in the **My Classes** screen.
- Tap a class to see instructor details and your local attendance summary.

## Roster-Aware Absence Logic
For events linked to a class, the system automatically identifies students who are part of the class but have not scanned.
- **Present**: Successfully scanned.
- **Rejected**: Attempted scan failed (e.g., geofence).
- **Absent**: Enrolled student with no scan record for the event.
