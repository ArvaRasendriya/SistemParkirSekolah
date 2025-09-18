# TODO: Implement Satgas Account Approval Flow

## Overview
Implement a system where Satgas users must be approved by an admin after email verification before they can log in. This includes creating a pending status for new accounts, blocking login for unapproved users, and providing an admin interface to approve accounts.

## Steps to Complete

### 1. Modify AuthService to handle profile creation and status checks
- [ ] Add method to create profile with 'pending' status after sign up
- [ ] Add method to get user status from profiles table
- [ ] Add method for admin to approve/reject accounts

### 2. Update Register Page to create profile after sign up
- [ ] Modify signUp method in register_page.dart to create profile record with status 'pending'

### 3. Update Auth Gate to check approval status
- [ ] Modify auth.gate.dart to check user status before allowing access to ProfilePage
- [ ] Show appropriate message for pending approval users

### 4. Create Admin Approval Page
- [ ] Create new page lib/pages/admin_approval_page.dart
- [ ] Display list of pending accounts
- [ ] Add approve/reject buttons for each account
- [ ] Update profile status when admin approves/rejects

### 5. Update Profile Page to show approval status
- [ ] Modify profile_page.dart to display current approval status
- [ ] Show different UI/messages based on status (pending, approved, rejected)

### 6. Testing and Integration
- [ ] Test complete flow: register -> pending -> admin approve -> login works
- [ ] Test login blocking for unapproved users
- [ ] Test admin approval interface
- [ ] Ensure email verification still works with the new flow
