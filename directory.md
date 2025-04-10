# Sandoog Application Directory

## Overview
Sandoog is a group savings management application built with Flutter. It allows users to create groups, manage members, set savings goals, track contributions, and handle withdrawal requests. It supports two types of groups: Standard Savings Groups and Lump Sum Lottery Groups.

## Features

### User Authentication
- **User Login**
- **User Sign Up**

### User Sorting After Login
Upon logging in, users are sorted into the following categories:
- **Normal User**
- **Normal User who requested to join a group**
- **User who requested to become a holder**
- **Normal User who is already in a group**
- **Holder User**
- **Admin User**

Based on their category, users will be directed to different screens.

### Group Management
- **Create groups** with an administrator.
- **Two group types:**
  - **Standard Savings Groups:** Members contribute monthly towards a goal.
  - **Lump Sum Lottery Groups:** Members contribute monthly, and at the end of each month, one randomly selected member receives the entire pool. This continues until all members have received the lump sum once.
- **Add and remove group members.**
- **Set a monthly savings goal** for the group (for Standard Savings Groups).

### Group Structure
Each group will have:
- **A dedicated table** named after the group ID, which will contain:
  - **Columns:** User IDs as columns and rows representing monthly contributions.
  - **First Row:** Indicates the starting month for contributions (e.g., "2-2024" for February 2024).

- **A metadata table** for each group (named `metadata_<group_id>`) that will include:
  - **Total Group Savings Goal**
  - **Actual Pool Amount** (calculated monthly)
  - **Group Holder**
  - **Current Withdrawals** (for Standard Savings Groups)

- **A withdrawals table** for Standard Savings Groups (named `withdrawals_<group_id>`) that will track:
  - **User ID**: The ID of the user requesting the withdrawal.
  - **Amount**: The amount requested for withdrawal.
  - **Status**: The status of the withdrawal request (pending, approved, rejected, cashed, being paid back, paid back in full).
  - **Request Date**: The date the withdrawal request was made.
  - **Approval Date**: The date the withdrawal request was approved or rejected.
  - **Payback Duration**: The duration for which the payback is scheduled.
  - **Payback Amount**: The amount to be paid back monthly.

- **A different metadata table** for Lump Sum Lottery Groups (named `lottery_metadata_<group_id>`) that will include:
  - **Total Group Savings Goal**
  - **Actual Pool Amount** (calculated monthly)
  - **Group Holder**
  - **Next Draw Date**
  - **Current Pool Amount**

### Savings Tracking
- **Users can mark their monthly contributions.**
- **Track the overall group savings progress** towards the goal (for Standard Savings Groups).
- **Contribution Deficit Tracking:** Displays how much a user is behind on their contributions (e.g., "X dirhams behind").

### Withdrawal Requests (Standard Savings Groups Only)
- **Users can request withdrawals** from the group's savings pool.
- **Administrators can approve or reject withdrawal requests.**
- **Set a payback rate** (without interest) for withdrawals, which is added to the monthly dues.

### Lump Sum Lottery (Lump Sum Lottery Groups Only)
- At the end of each month, a random member is selected to receive the total pooled funds.
- The selection process continues monthly until every member has won once.

## Technologies Used
- **Flutter**

## List of Screens

### Authentication Screens
1. **Login Screen**
   - Users can log in to their accounts using their email and password.
   
2. **Sign Up Screen**
   - New users can create an account by providing their email and setting a password.

3. **User Landing Screen**
   - For users who have not requested to become holders, have not requested to join a group, are not in a group, and are not holders yet. This screen provides options to request to join a group or request to become a holder.
   - Also displays status for users who have pending requests.
   - Routes users to appropriate screens based on their role and group status:
     - Normal users with no group see the landing page options
     - Normal users with a group are directed to the appropriate group dashboard
     - Users who requested to be a holder or join a group see status messages
     - Holders are directed to holder dashboard or create group screen
     - Admins are directed to admin dashboard

4. **User Request Holder Screen**
   - Allows users to submit a request to become a group holder.
   - Explains the responsibilities of a holder and confirms user interest.

5. **User Request Join Group Screen**
   - Allows users to enter a group code to request joining an existing group.
   - Validates the group code and submits the join request to the group holder.

### Admin Screens
6. **Admin Dashboard**
   - Admins can manage users and groups, view statistics, and oversee group activities.

7. **Admin Approve Holder Screen**
   - Admins can approve or reject requests from users wanting to become holders, ensuring proper management of group leaders.

8. **Admin See Users Screen**
   - Admins can view all registered users, their roles, and their group affiliations.

### Holder Screens
9. **Holder Dashboard**
   - Overview for holders to manage their group, including member activities and contributions.

10. **Holder Create Screen**
    - Holders can create a new group, setting the group name, type, and savings goal.

11. **Holder Manage Group Screen**
    - Holders can see the group code, copy it, and send it to users for joining. They can also manage member requests, view active members, and see group details such as savings goals and current total pool.

12. **Holder See Request Screen**
    - Holders can view requests from users wanting to join their group and approve or reject them.

13. **Holder Manage Members Screen**
    - Holders can add or remove members from their group, ensuring the group remains manageable.

14. **Holder Group Details Screen**
    - Displays group information, including savings goals, current total pool, and member contributions.

15. **Holder Lottery Winner Selection Screen**
    - Holders can initiate the lottery process to select a winner from the group.

16. **Holder Manage Withdrawal Screen**
    - Holders can view and manage withdrawal requests from group members.

### User Normal Group Screens 
17. **User Normal Group Dashboard**
    - Overview for users in a standard group. Users can input their monthly contributions and see if they are on track or behind month over month.

18. **User Group Overview Tracking Screen**
    - Users can track their contributions and overall group progress towards the savings goal.

19. **User Withdrawal Request Screen**
    - Users can submit withdrawal requests from the group's savings pool.

### User Lottery Group Screens
20. **User Lottery Group Dashboard**
    - Overview for users in a lottery group. Users can input their monthly contributions and see if they are on track or behind month over month.

21. **User Lottery Group Overview Tracking Screen**
    - Users can track their contributions and the status of the lottery pool.

22. **User Lottery Winner Group Screen**
    - Displays information about the lottery winnings, including amounts won and collection status.

## Services
1. **Authentication Service**
   - Handles user login and sign-up using Supabase. Admins will have hard-coded logic for authentication using Supabase email and password, but the role will not be checked in Supabase. Any user with an email ending in `@sandoog` will be considered an admin.

2. **Group Management Service**
   - Manages group creation, member addition/removal, and group details.

3. **Savings Tracking Service**
   - Tracks user contributions and overall group savings progress.

4. **Withdrawal Management Service**
   - Manages withdrawal requests and admin approvals.

5. **Lottery Management Service**
   - Handles the selection process for Lump Sum Lottery Groups.

6. **Contribution Calculation Service**
   - Calculates the total contributions for each group monthly and updates the metadata table with the total pool amount and savings goal.

## Data Models

### User Model
- **Fields:**
  - `id`: Unique identifier for the user.
  - `email`: User's email address (used for authentication).
  - `role`: User's role (normal user, holder, admin).
  - `group_id`: Foreign key referencing the group the user belongs to (if any).
  - `created_at`: Timestamp for when the user was created.
  - `updated_at`: Timestamp for when the user was last updated.

### Group Model
- **Fields:**
  - `id`: Unique identifier for the group.
  - `name`: Name of the group.
  - `type`: Type of the group (Standard Savings or Lump Sum Lottery).
  - `savings_goal`: Monthly savings goal for the group.
  - `holder_id`: Foreign key referencing the holder of the group.
  - `created_at`: Timestamp for when the group was created.
  - `updated_at`: Timestamp for when the group was last updated.

### Monthly Log Model
- **Fields:**
  - `id`: Unique identifier for the log entry.
  - `group_id`: Foreign key referencing the group.
  - `month`: Month for which the contributions are recorded.
  - `year`: Year for which the contributions are recorded.
  - `contributions`: JSON or structured data containing user IDs as keys and their contributions as values.
  - **Note:** This model is somewhat redundant due to the group-specific contribution logs but serves as a secondary check for contributions.
  - `created_at`: Timestamp for when the log entry was created.
  - `updated_at`: Timestamp for when the log entry was last updated.

### Group Metadata Model (Standard Savings Groups)
- **Fields:**
  - `id`: Unique identifier for the metadata entry.
  - `group_id`: Foreign key referencing the group.
  - `total_savings_goal`: Total savings goal for the group.
  - `actual_pool_amount`: Current total amount in the group's savings pool.
  - `holder_id`: Foreign key referencing the holder of the group.
  - `current_withdrawals`: Total amount of withdrawals requested.
  - `created_at`: Timestamp for when the metadata entry was created.
  - `updated_at`: Timestamp for when the metadata entry was last updated.

### Withdrawals Model (Standard Savings Groups)
- **Fields:**
  - `id`: Unique identifier for the withdrawal request.
  - `group_id`: Foreign key referencing the group.
  - `user_id`: Foreign key referencing the user requesting the withdrawal.
  - `amount`: Amount requested for withdrawal.
  - `status`: Status of the withdrawal request (pending, approved, rejected, being paid back, paid back in full).
  - `request_date`: Date the withdrawal request was made.
  - `approval_date`: Date the withdrawal request was approved or rejected.
  - `payback_duration`: The duration for which the payback is scheduled.
  - `payback_amount`: The amount to be paid back monthly.

### Group Metadata Model (Lump Sum Lottery Groups)
- **Fields:**
  - `id`: Unique identifier for the metadata entry.
  - `group_id`: Foreign key referencing the group.
  - `total_savings_goal`: Total savings goal for the group.
  - `actual_pool_amount`: Current total amount in the group's savings pool.
  - `holder_id`: Foreign key referencing the holder of the group.
  - `next_draw_date`: The date of the next lottery draw.
  - `current_pool_amount`: The current amount in the lottery pool.
  - `created_at`: Timestamp for when the metadata entry was created.
  - `updated_at`: Timestamp for when the metadata entry was last updated.

## Database Structure
- **Users Table**
  - Columns: `id`, `email`, `role`, `group_id`, `created_at`, `updated_at`

- **Group Metadata Table (Standard Savings Groups)**
  - Columns: `id`, `group_id`, `total_savings_goal`, `actual_pool_amount`, `holder_id`, `current_withdrawals`, `created_at`, `updated_at`

- **Withdrawals Table (Standard Savings Groups)**
  - Columns: `id`, `group_id`, `user_id`, `amount`, `status`, `request_date`, `approval_date`, `payback_duration`, `payback_amount`

- **Group Metadata Table (Lump Sum Lottery Groups)**
  - Columns: `id`, `group_id`, `total_savings_goal`, `actual_pool_amount`, `holder_id`, `next_draw_date`, `current_pool_amount`, `created_at`, `updated_at`

- **Group-Specific Tables**
  - Each group will have its own table named after the group ID.
  - **Columns:** User IDs as columns and rows representing monthly contributions.
  - **First Row:** Indicates the starting month for contributions (e.g., "2-2024" for February 2024).

### Supabase Usage
- **Authentication:** Supabase will handle user authentication, including sign-up and login processes. Passwords will be securely hashed and stored.
- **Database Management:** Supabase will manage the PostgreSQL database, allowing for easy querying and data manipulation.
- **Real-time Updates:** Supabase can provide real-time updates for group contributions and member activities, enhancing user experience.
- **Role Management:** While Supabase will not enforce role checks, the application will implement logic to determine user roles based on their email addresses.

## App Colors
- **Primary Color:** Green (#307351)
- **Secondary Color:** Blue (#3e6990)
- **Dark Color:** Dark Purple (#381d2a)
