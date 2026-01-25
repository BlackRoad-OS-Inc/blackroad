# 📝 GreenLight Notion Integration

**Extension to GreenLight for Notion Knowledge Management**

---

## 📝 Notion Events as GreenLight Steps

Map Notion events directly to GreenLight workflow:

| Notion Event | GreenLight Step | Step # | Emoji | State Transition | Context |
|--------------|-----------------|--------|-------|------------------|---------|
| Page created | ⚡ Impulse | 1 | ⚡📄 | void → inbox | any database |
| Database item added | 📥 Capture | 3 | 📥📊 | → inbox | any database |
| Comment added | 💬 Collaborate | 11 | 💬📝 | → wip | any page |
| Page updated | ⚙️ Execute | 13 | ⚙️✏️ | → wip | any page |
| Task completed | ✅ Approve | 7 | ✅☑️ | → queued | task database |
| Page published | 🎉 Complete | 19 | 🎉📰 | wip → done | public pages |
| Page archived | 📦 Archive | 27 | 📦🗄️ | → void | any page |

---

## 🗂️ Notion Database Categories

Recommended database structure with GreenLight mappings:

| Emoji | Database | Purpose | GreenLight Domain | Properties |
|-------|----------|---------|-------------------|------------|
| 📋 | Tasks | Task management | Platform (🛣️) | Status, Priority, Assignee |
| 📚 | Documentation | Knowledge base | Documentation (📚) | Category, Status, Tags |
| 🎯 | Projects | Project tracking | Platform (🛣️) | Phase, Owner, Timeline |
| 🧠 | Ideas | Innovation backlog | Research (🔬) | Stage, Votes, Feasibility |
| 👥 | Team | People directory | Platform (🛣️) | Role, Department, Skills |
| 📊 | Metrics | KPI tracking | Platform (🛣️) | Value, Target, Trend |
| 🎨 | Design | Design system | Design (🎨) | Type, Status, Figma link |
| 💼 | Clients | Client management | Platform (🛣️) | Tier, Status, Revenue |
| 🔬 | Research | R&D notes | Research (🔬) | Topic, Status, Findings |
| 📅 | Events | Calendar/meetings | Platform (🛣️) | Date, Type, Attendees |

---

## 🏷️ Notion Property Types as GreenLight Tags

| Property Type | Emoji | GreenLight Usage | Example |
|---------------|-------|------------------|---------|
| Status | 🚦 | Workflow state | Not started, In Progress, Done |
| Priority | 🔥 | Priority level | High, Medium, Low |
| Person | 👤 | Assignment | @alexa, @team |
| Date | 📅 | Timeline | Due date, Created date |
| Checkbox | ☑️ | Binary state | Completed, Published |
| Select | 🏷️ | Category | Type, Category, Stage |
| Multi-select | 🏷️🏷️ | Tags | Tags, Labels, Skills |
| Relation | 🔗 | Cross-reference | Related pages, Dependencies |
| Rollup | 📊 | Aggregation | Count, Sum, Average |
| Formula | 🧮 | Computed | Progress %, Days remaining |

---

## 🎨 Composite Patterns for Notion

### Page Operations
```
⚡📄👉📌 = New page created, micro scale
📝✏️🎢📚 = Documentation updated, macro scale
🎉📰🎢🌍 = Page published, macro impact
```

### Database Operations
```
📊📥👉📌 = Database item added, micro
☑️✅👉📌 = Task completed
🔗📊🎢📌 = Relation created, macro
```

### Collaboration Events
```
💬📝👉⭐ = Comment added, high priority
👥📄👉📌 = Page shared with team
🔔📄👉⭐ = Page mention notification
```

### Content Updates
```
⚙️✏️👉📌 = Page edited, micro
📸🎨🎢⭐ = Image/design added, macro, high priority
🔢📊👉📌 = Data updated in database
```

### Full Notion Flow
```
[⚡📄] [📝✏️] [💬📝] [✅☑️] [🎉📰] = Create → Edit → Comment → Approve → Publish
[📊📥] [🔢📊] [🔗📊] [📈✅] = DB add → Update → Relate → Complete
```

---

## 📝 NATS Subject Patterns (Notion)

### Page Events
```
greenlight.notion.page.created.micro.docs.{page_id}
greenlight.notion.page.updated.micro.docs.{page_id}
greenlight.notion.page.deleted.micro.docs.{page_id}
greenlight.notion.page.published.macro.docs.{page_id}
```

### Database Events
```
greenlight.notion.database.item_added.micro.platform.{database_id}
greenlight.notion.database.item_updated.micro.platform.{database_id}
greenlight.notion.database.item_deleted.micro.platform.{database_id}
```

### Property Events
```
greenlight.notion.property.status_changed.micro.platform.{page_id}
greenlight.notion.property.assigned.micro.platform.{page_id}
greenlight.notion.property.date_set.micro.platform.{page_id}
```

### Block Events
```
greenlight.notion.block.added.micro.docs.{block_id}
greenlight.notion.block.updated.micro.docs.{block_id}
greenlight.notion.block.moved.micro.docs.{block_id}
```

### Comment Events
```
greenlight.notion.comment.added.micro.docs.{page_id}
greenlight.notion.comment.resolved.micro.docs.{comment_id}
greenlight.notion.mention.received.micro.docs.{user_id}
```

---

## 🔨 Notion Memory Templates

### Page Operations

```bash
# Page created
gl_notion_page_created() {
    local page_title="$1"
    local database="$2"
    local creator="${3:-unknown}"

    gl_log "⚡📄👉📌" \
        "page_created" \
        "$page_title" \
        "Database: $database, Creator: $creator"
}

# Page updated
gl_notion_page_updated() {
    local page_title="$1"
    local update_type="${2:-content}"  # content, properties, title

    local update_emoji=""
    case "$update_type" in
        content) update_emoji="✏️" ;;
        properties) update_emoji="🔢" ;;
        title) update_emoji="📝" ;;
        *) update_emoji="⚙️" ;;
    esac

    gl_log "${update_emoji}📄👉📌" \
        "page_updated" \
        "$page_title" \
        "Type: $update_type"
}

# Page published
gl_notion_page_published() {
    local page_title="$1"
    local public_url="$2"

    gl_log "🎉📰🎢🌍" \
        "page_published" \
        "$page_title" \
        "Public URL: $public_url"
}

# Page archived
gl_notion_page_archived() {
    local page_title="$1"
    local reason="${2:-manual}"

    gl_log "📦🗄️👉📌" \
        "page_archived" \
        "$page_title" \
        "Reason: $reason"
}

# Page shared
gl_notion_page_shared() {
    local page_title="$1"
    local shared_with="$2"
    local permission="${3:-read}"

    gl_log "👥📄👉📌" \
        "page_shared" \
        "$page_title" \
        "With: $shared_with, Permission: $permission"
}
```

### Database Operations

```bash
# Database item added
gl_notion_db_item_added() {
    local database_name="$1"
    local item_title="$2"
    local item_id="${3:-unknown}"

    gl_log "📊📥👉📌" \
        "db_item_added" \
        "$database_name" \
        "$item_title ($item_id)"
}

# Database item updated
gl_notion_db_item_updated() {
    local database_name="$1"
    local item_title="$2"
    local properties_changed="$3"

    gl_log "🔢📊👉📌" \
        "db_item_updated" \
        "$database_name" \
        "$item_title - Changed: $properties_changed"
}

# Status changed
gl_notion_status_changed() {
    local item_title="$1"
    local old_status="$2"
    local new_status="$3"

    local status_emoji=""
    case "$new_status" in
        "Not started") status_emoji="⚪" ;;
        "In progress") status_emoji="🔵" ;;
        "Done") status_emoji="✅" ;;
        "Blocked") status_emoji="🔴" ;;
        *) status_emoji="🚦" ;;
    esac

    gl_log "${status_emoji}🚦👉📌" \
        "status_changed" \
        "$item_title" \
        "$old_status → $new_status"
}

# Task completed
gl_notion_task_completed() {
    local task_title="$1"
    local assignee="$2"
    local duration="${3:-unknown}"

    gl_log "☑️✅🎢📌" \
        "task_completed" \
        "$task_title" \
        "By: $assignee, Duration: $duration"
}

# Relation created
gl_notion_relation_created() {
    local source_page="$1"
    local target_page="$2"
    local relation_type="${3:-related}"

    gl_log "🔗📊🎢📌" \
        "relation_created" \
        "$source_page" \
        "→ $target_page ($relation_type)"
}
```

### Comment Operations

```bash
# Comment added
gl_notion_comment_added() {
    local page_title="$1"
    local commenter="$2"
    local preview="${3:0:50}"

    gl_log "💬📝👉⭐" \
        "comment_added" \
        "$page_title" \
        "$commenter: $preview..."
}

# Comment resolved
gl_notion_comment_resolved() {
    local page_title="$1"
    local resolver="$2"

    gl_log "✅💬👉📌" \
        "comment_resolved" \
        "$page_title" \
        "Resolved by: $resolver"
}

# Mention received
gl_notion_mention() {
    local user="$1"
    local page_title="$2"
    local mentioner="$3"

    gl_log "🔔📄👉⭐" \
        "mention_received" \
        "$user" \
        "In: $page_title by $mentioner"
}
```

### Block Operations

```bash
# Block added
gl_notion_block_added() {
    local block_type="$1"  # heading, paragraph, code, image, etc.
    local page_title="$2"

    local block_emoji=""
    case "$block_type" in
        heading_1|heading_2|heading_3) block_emoji="📌" ;;
        paragraph) block_emoji="📝" ;;
        code) block_emoji="💻" ;;
        image) block_emoji="🖼️" ;;
        table) block_emoji="📊" ;;
        bullet_list) block_emoji="📋" ;;
        *) block_emoji="📄" ;;
    esac

    gl_log "${block_emoji}➕👉📌" \
        "block_added" \
        "$page_title" \
        "Block type: $block_type"
}

# Block updated
gl_notion_block_updated() {
    local block_type="$1"
    local page_title="$2"
    local change="${3:-content}"

    gl_log "⚙️📝👉📌" \
        "block_updated" \
        "$page_title" \
        "$block_type updated: $change"
}
```

### Sync Operations

```bash
# Notion sync started
gl_notion_sync_started() {
    local sync_type="$1"  # full, incremental
    local databases="$2"

    gl_log "🔄📊👉📌" \
        "sync_started" \
        "$sync_type" \
        "Databases: $databases"
}

# Notion sync completed
gl_notion_sync_completed() {
    local sync_type="$1"
    local items_synced="$2"
    local duration="$3"

    gl_log "✅🔄🎢📌" \
        "sync_completed" \
        "$sync_type" \
        "$items_synced items synced in $duration"
}
```

---

## 🎯 Example Integration: Complete Notion Workflow

### Scenario: Documentation page creation and collaboration

```bash
# 1. Page created in Documentation database
gl_notion_page_created "API Authentication Guide" "Documentation" "alexa"
# [⚡📄👉📌] page_created: API Authentication Guide — Database: Documentation, Creator: alexa

# 2. Content added
gl_notion_block_added "heading_1" "API Authentication Guide"
# [📌➕👉📌] block_added: API Authentication Guide — Block type: heading_1

gl_notion_block_added "code" "API Authentication Guide"
# [💻➕👉📌] block_added: API Authentication Guide — Block type: code

# 3. Page updated with more content
gl_notion_page_updated "API Authentication Guide" "content"
# [✏️📄👉📌] page_updated: API Authentication Guide — Type: content

# 4. Team member adds comment
gl_notion_comment_added "API Authentication Guide" "developer" "Should we add OAuth2 flow example?"
# [💬📝👉⭐] comment_added: API Authentication Guide — developer: Should we add OAuth2 flow example?...

# 5. Owner responds and resolves
gl_notion_comment_resolved "API Authentication Guide" "alexa"
# [✅💬👉📌] comment_resolved: API Authentication Guide — Resolved by: alexa

# 6. Page published
gl_notion_page_published "API Authentication Guide" "https://blackroad.notion.site/api-auth"
# [🎉📰🎢🌍] page_published: API Authentication Guide — Public URL: https://blackroad.notion.site/api-auth
```

### Scenario: Task management workflow

```bash
# 1. Task added to database
gl_notion_db_item_added "Tasks" "Implement Notion webhook handler" "task-123"
# [📊📥👉📌] db_item_added: Tasks — Implement Notion webhook handler (task-123)

# 2. Status changed to In Progress
gl_notion_status_changed "Implement Notion webhook handler" "Not started" "In progress"
# [🔵🚦👉📌] status_changed: Implement Notion webhook handler — Not started → In progress

# 3. Task updated with notes
gl_notion_db_item_updated "Tasks" "Implement Notion webhook handler" "Notes, Code snippet"
# [🔢📊👉📌] db_item_updated: Tasks — Implement Notion webhook handler - Changed: Notes, Code snippet

# 4. Related to documentation page
gl_notion_relation_created "Implement Notion webhook handler" "API Authentication Guide" "references"
# [🔗📊🎢📌] relation_created: Implement Notion webhook handler — → API Authentication Guide (references)

# 5. Task completed
gl_notion_task_completed "Implement Notion webhook handler" "alexa" "2h 45m"
# [☑️✅🎢📌] task_completed: Implement Notion webhook handler — By: alexa, Duration: 2h 45m

# 6. Status changed to Done
gl_notion_status_changed "Implement Notion webhook handler" "In progress" "Done"
# [✅🚦👉📌] status_changed: Implement Notion webhook handler — In progress → Done
```

### Scenario: Full sync operation

```bash
# 1. Start sync
gl_notion_sync_started "incremental" "Tasks, Documentation, Projects"
# [🔄📊👉📌] sync_started: incremental — Databases: Tasks, Documentation, Projects

# 2. Sync completes
gl_notion_sync_completed "incremental" "47" "3.2s"
# [✅🔄🎢📌] sync_completed: incremental — 47 items synced in 3.2s
```

---

## 📊 Notion Integration Details

**Workspace:** BlackRoad OS Workspace
**API Version:** 2022-06-28
**API Endpoint:** https://api.notion.com/v1/

### Recommended Databases:

1. **Tasks** (📋)
   - Properties: Title, Status, Priority, Assignee, Due Date, Tags
   - Views: Board, List, Calendar, Timeline

2. **Documentation** (📚)
   - Properties: Title, Category, Status, Tags, Last Updated
   - Views: Gallery, Table, Timeline

3. **Projects** (🎯)
   - Properties: Title, Phase, Owner, Start Date, End Date, Status
   - Views: Timeline, Board, Table

4. **Ideas** (🧠)
   - Properties: Title, Stage, Votes, Feasibility, Owner
   - Views: Gallery, Board, Table

5. **Team** (👥)
   - Properties: Name, Role, Department, Skills, Email
   - Views: Gallery, Table

---

## 📚 Integration Checklist

- [x] Mapped Notion events to GreenLight 27-step workflow
- [x] Created database-to-domain mappings
- [x] Defined property types as GreenLight tags
- [x] Extended NATS subjects for Notion events
- [x] Built 15+ Notion-specific templates
- [x] Page lifecycle tracking
- [x] Database CRUD operations
- [x] Comment and collaboration events
- [x] Block-level operations
- [x] Sync operations
- [x] Relation tracking
- [x] Status transitions

---

**Created:** December 23, 2025
**For:** Notion Knowledge Management Integration
**Version:** 2.0.0-notion
**Status:** 🔨 IMPLEMENTATION

