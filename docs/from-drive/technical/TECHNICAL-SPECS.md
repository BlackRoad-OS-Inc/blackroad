BlackRoad Technical Specifications
User Flows, Database Schemas, API Endpoints, Components
PART 1: USER FLOWS
1.1 User Signup Flow
User lands on any BlackRoad property (blackroad.io, lucidia.earth, etc.)
Clicks "Sign Up" or "Get Started" CTA
Modal appears with options: Continue with Google, Continue with GitHub, Email signup
If OAuth: Redirect to provider, return with tokens, create/link account
If Email: Enter email, password, display name
Email verification sent
User clicks verification link
Onboarding survey: What brings you here? (Creator/Business/Student/Developer)
Based on answer, redirect to appropriate dashboard
Show quick tour overlay (skippable)
1.2 Lucidia Chat Flow
User navigates to lucidia.earth/chat
If not authenticated: Show signup prompt with 5 free sessions/day offer
If authenticated: Load last conversation or new chat
User types message in input field
System checks: Model selection, file attachments, context from memory
Message sent to API with full context
Streaming response displayed in real-time
Response saved to memory system with PS-SHA∞ hash
Context panel updates with related memories
User can: Copy, regenerate, edit, branch, rate response
1.3 Subscription Upgrade Flow
User hits usage limit or clicks "Upgrade" button
Pricing modal appears with tier comparison
User selects tier (Creator $20/mo, Team $100/seat, etc.)
Toggle for monthly/annual billing (20% discount for annual)
Click "Continue to Payment"
Stripe Checkout opens (hosted or embedded)
User enters payment details
Stripe webhook confirms payment
User record updated with new tier
Success screen with new features unlocked
Confirmation email sent
1.4 Consulting Booking Flow (aliceqi.com)
User lands on aliceqi.com or aliceqi.com/consulting
Reviews service tiers: Strategy Session, Implementation Sprint, Retainer
Clicks "Book Now" on desired tier
Calendly embed opens with available time slots
User selects date/time
Enters name, email, company, brief description of needs
If paid session: Stripe payment required
Confirmation email sent with calendar invite
Reminder emails at 24h and 1h before
Follow-up email with deliverables after session
1.5 RoadView Creator Onboarding
User clicks "Start Creating" on roadview.tv
If not signed in: Signup flow
Creator application form: Channel name, content category, sample content links
Agree to creator terms (including 80-90% revenue share)
Application submitted for review (during beta)
Approval email sent (or auto-approve post-beta)
Redirect to Creator Studio
First upload wizard: Upload video, AI generates thumbnail options, enter title/description
Video published to channel
Analytics available immediately
1.6 RoadWork Student Learning Flow
Student lands on roadwork.edu
Clicks "I&apos;m a Student"
Signup (free, no payment required)
Onboarding: Grade level, subjects of interest, learning goals
Optional: Diagnostic assessment to determine starting level
Dashboard populated with recommended lessons
Student clicks on a lesson
Lesson content displayed with interactive elements
Practice problems interspersed
If stuck: AI tutor offers hints, explanations
Lesson completion: XP awarded, streak updated
Next lesson recommended based on performance
PART 2: DATABASE SCHEMAS
Primary database: PostgreSQL via Supabase. All tables include created_at, updated_at timestamps.
2.1 users
Column
Type
Description
id
uuid (PK)
Primary key, auto-generated
email
text (unique)
User email address
display_name
text
Public display name
avatar_url
text
Profile image URL
auth_provider
enum
google, github, email
auth_provider_id
text
ID from OAuth provider
role
enum
user, creator, admin
tier
enum
free, creator, team, enterprise
stripe_customer_id
text
Stripe customer ID
email_verified
boolean
Email verification status
onboarding_completed
boolean
Has completed onboarding
preferences
jsonb
User preferences object
2.2 subscriptions
Column
Type
Description
id
uuid (PK)
Primary key
user_id
uuid (FK)
References users.id
stripe_subscription_id
text
Stripe subscription ID
product
enum
lucidia, prism, roadview, roadwork, blackroad_os
tier
enum
free, pro, team, enterprise
status
enum
active, canceled, past_due, trialing
billing_cycle
enum
monthly, annual
current_period_start
timestamp
Start of current billing period
current_period_end
timestamp
End of current billing period
cancel_at_period_end
boolean
Will cancel at period end
2.3 conversations (Lucidia)
Column
Type
Description
id
uuid (PK)
Primary key
user_id
uuid (FK)
References users.id
title
text
Conversation title (auto-generated or user-set)
model
text
Primary model used (gpt-4, claude, etc.)
folder_id
uuid (FK)
Optional folder reference
pinned
boolean
Is conversation pinned
archived
boolean
Is conversation archived
memory_hash
text
PS-SHA∞ hash of conversation state
token_count
integer
Total tokens in conversation
2.4 messages (Lucidia)
Column
Type
Description
id
uuid (PK)
Primary key
conversation_id
uuid (FK)
References conversations.id
role
enum
user, assistant, system
content
text
Message content
model
text
Model used for this message
parent_id
uuid (FK)
Parent message (for branching)
tokens
integer
Token count for this message
attachments
jsonb
Array of file attachments
rating
integer
User rating (-1, 0, 1)
memory_hash
text
PS-SHA∞ hash at this point
2.5 memories (Lucidia)
Column
Type
Description
id
uuid (PK)
Primary key
user_id
uuid (FK)
References users.id
content
text
Memory content/summary
embedding
vector(1536)
Vector embedding for semantic search
source_conversation_id
uuid (FK)
Origin conversation
source_message_id
uuid (FK)
Origin message
memory_type
enum
fact, preference, context, skill
importance
float
Importance score (0-1)
hash
text
PS-SHA∞ hash for verification
tags
text[]
Array of tags
2.6 agents (Prism Console)
Column
Type
Description
id
uuid (PK)
Primary key
owner_id
uuid (FK)
References users.id
name
text
Agent name
description
text
Agent description
model
text
Default model for agent
system_prompt
text
Agent system prompt
capabilities
text[]
List of capabilities
status
enum
active, paused, disabled
config
jsonb
Agent configuration
memory_enabled
boolean
Has persistent memory
public
boolean
Listed in marketplace
2.7 videos (RoadView)
Column
Type
Description
id
uuid (PK)
Primary key
creator_id
uuid (FK)
References users.id
title
text
Video title
description
text
Video description
video_url
text
Storage URL for video file
thumbnail_url
text
Thumbnail image URL
duration
integer
Duration in seconds
visibility
enum
public, unlisted, private, scheduled
scheduled_at
timestamp
Scheduled publish time
category
text
Content category
tags
text[]
Video tags
transcript
text
Auto-generated transcript
embedding
vector(1536)
Semantic embedding for search
view_count
integer
Total views
like_count
integer
Total likes
2.8 lessons (RoadWork)
Column
Type
Description
id
uuid (PK)
Primary key
subject
text
Subject (math, science, etc.)
topic
text
Specific topic
title
text
Lesson title
content
jsonb
Lesson content blocks
grade_level
integer
Target grade level
difficulty
enum
beginner, intermediate, advanced
prerequisites
uuid[]
Required prior lessons
xp_reward
integer
XP for completion
estimated_minutes
integer
Estimated completion time
2.9 student_progress (RoadWork)
Column
Type
Description
id
uuid (PK)
Primary key
user_id
uuid (FK)
References users.id
lesson_id
uuid (FK)
References lessons.id
status
enum
not_started, in_progress, completed
progress_percent
integer
Completion percentage
score
integer
Assessment score (if applicable)
attempts
integer
Number of attempts
time_spent
integer
Seconds spent on lesson
completed_at
timestamp
Completion timestamp
xp_earned
integer
XP earned from lesson
PART 3: API ENDPOINTS
Base URL: api.blackroad.io/v1
Authentication: Bearer token in Authorization header
3.1 Authentication
Method
Endpoint
Description
POST
/auth/signup
Create new account with email/password
POST
/auth/login
Login with email/password
POST
/auth/oauth/:provider
OAuth flow (google, github)
POST
/auth/logout
Invalidate session
POST
/auth/refresh
Refresh access token
POST
/auth/verify-email
Verify email address
POST
/auth/forgot-password
Request password reset
POST
/auth/reset-password
Reset password with token
3.2 Users
Method
Endpoint
Description
GET
/users/me
Get current user profile
PATCH
/users/me
Update current user profile
DELETE
/users/me
Delete account
GET
/users/me/usage
Get usage stats for billing period
GET
/users/:id
Get public user profile
3.3 Chat (Lucidia)
Method
Endpoint
Description
GET
/conversations
List user conversations
POST
/conversations
Create new conversation
GET
/conversations/:id
Get conversation with messages
PATCH
/conversations/:id
Update conversation (title, folder)
DELETE
/conversations/:id
Delete conversation
POST
/conversations/:id/messages
Send message (streams response)
POST
/conversations/:id/branch
Branch from message
POST
/chat/completion
One-off completion (no conversation)
3.4 Memory (Lucidia)
Method
Endpoint
Description
GET
/memories
List memories with pagination
GET
/memories/search
Semantic search across memories
GET
/memories/:id
Get specific memory
DELETE
/memories/:id
Delete specific memory
GET
/memories/verify/:hash
Verify memory hash
POST
/memories/export
Export all memories
3.5 Agents (Prism Console)
Method
Endpoint
Description
GET
/agents
List user&apos;s agents
POST
/agents
Create new agent
GET
/agents/:id
Get agent details
PATCH
/agents/:id
Update agent
DELETE
/agents/:id
Delete agent
POST
/agents/:id/invoke
Invoke agent with input
GET
/agents/:id/logs
Get agent execution logs
GET
/agents/marketplace
Browse public agents
3.6 Billing
Method
Endpoint
Description
GET
/billing/subscription
Get current subscription
POST
/billing/checkout
Create Stripe checkout session
POST
/billing/portal
Create Stripe customer portal session
GET
/billing/invoices
List invoices
POST
/billing/webhooks/stripe
Stripe webhook handler
PART 4: COMPONENT SPECIFICATIONS
Reusable components across all BlackRoad properties. Built with React + Tailwind + shadcn/ui.
4.1 Navbar
Logo: BlackRoad logo, links to homepage of current domain
Nav Links: Product, Pricing, Docs, Blog (configurable per domain)
Right Section (logged out): Sign In, Get Started button
Right Section (logged in): Avatar dropdown with Dashboard, Settings, Logout
Mobile: Hamburger menu, slide-out drawer
4.2 AuthModal
Modes: signup, login, forgot-password
OAuth Buttons: Continue with Google, Continue with GitHub
Divider: "or continue with email"
Email Form: Email, password, confirm password (signup only)
Toggle: "Already have an account? Sign in" / "Don&apos;t have an account? Sign up"
Validation: Email format, password strength, match confirmation
4.3 PricingTable
Props: product (lucidia, prism, etc.), billingCycle (monthly/annual)
Toggle: Monthly / Annual with savings callout
Tier Cards: Name, price, feature list, CTA button
Current Plan Badge: If user is on that tier, show "Current Plan"
Popular Badge: Highlight recommended tier
4.4 ChatMessage
Props: message object (role, content, model, timestamp)
User Message: Right-aligned, user avatar
Assistant Message: Left-aligned, model icon
Content: Markdown rendering, code syntax highlighting
Actions (on hover): Copy, Edit, Regenerate, Branch
Rating: Thumbs up/down
4.5 ChatInput
Textarea: Auto-expanding, placeholder text
Model Selector: Dropdown to choose model
Attach Button: File upload (images, documents)
Send Button: Submit message, shows loading state
Keyboard: Enter to send, Shift+Enter for newline
4.6 VideoCard (RoadView)
Thumbnail: 16:9 aspect ratio, hover preview
Duration Badge: Bottom right of thumbnail
Title: Max 2 lines, truncate with ellipsis
Creator: Avatar and name, links to channel
Stats: View count, time since published
4.7 LessonCard (RoadWork)
Icon: Subject icon
Title: Lesson title
Progress Bar: If in progress, show completion percentage
XP Badge: XP reward for completion
Time Estimate: "~15 min"
Status: Locked (prereqs not met), Available, In Progress, Completed
PART 5: SEO & ANALYTICS
5.1 SEO Requirements
Meta Tags (per page):
title: Unique, under 60 characters
description: Unique, under 160 characters
og:title, og:description, og:image for social sharing
twitter:card, twitter:title, twitter:description, twitter:image
canonical URL
Technical SEO:
Sitemap.xml generated for each domain
Robots.txt configured properly
Structured data (JSON-LD) for articles, products, FAQs
Page speed: Target 90+ on Lighthouse
Mobile-first responsive design
5.2 Analytics Requirements
Tracking (via Plausible or PostHog):
Page views
Unique visitors
Bounce rate
Session duration
Traffic sources
Geographic distribution
Custom Events:
signup_started, signup_completed
chat_message_sent
upgrade_clicked, upgrade_completed
video_uploaded, video_watched
lesson_started, lesson_completed
agent_created, agent_invoked
consulting_booked
5.3 Conversion Funnels
Signup Funnel:
Landing → Click CTA → Signup Modal → OAuth/Email → Verification → Onboarding → Dashboard
Upgrade Funnel:
Free Usage → Hit Limit → Pricing Modal → Select Tier → Checkout → Payment → Success
Consulting Funnel:
Landing → Services Page → Book CTA → Calendly → Select Time → Payment → Confirmation
End of Technical Specifications
