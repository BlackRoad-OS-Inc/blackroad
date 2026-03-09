# 🎨 GreenLight Canva Integration

**Extension to GreenLight for Canva Design Workflow**

---

## 🎨 Canva Events as GreenLight Steps

Map Canva events directly to GreenLight workflow:

| Canva Event | GreenLight Step | Step # | Emoji | State Transition | Context |
|-------------|-----------------|--------|-------|------------------|---------|
| Design created | ⚡ Impulse | 1 | ⚡🎨 | void → inbox | any design |
| Template used | 📥 Capture | 3 | 📥🖼️ | → inbox | from template |
| Asset uploaded | 📤 Upload | 5 | 📤🖼️ | → inbox | images/videos |
| Design edited | ⚙️ Execute | 13 | ⚙️✏️ | → wip | any design |
| Comment added | 💬 Collaborate | 11 | 💬🎨 | → wip | team feedback |
| Design approved | ✅ Approve | 7 | ✅👍 | → queued | review workflow |
| Design published | 🎉 Complete | 19 | 🎉🎨 | wip → done | published |
| Design exported | 📦 Export | 18 | 📦💾 | done → void | downloaded |

---

## 🎨 Canva Design Types

Design categories with GreenLight mappings:

| Emoji | Design Type | Purpose | GreenLight Domain | Common Formats |
|-------|-------------|---------|-------------------|----------------|
| 📱 | Social Media | Posts, stories, ads | Marketing (📣) | PNG, JPG, MP4 |
| 📄 | Presentation | Slides, pitch decks | Platform (🛣️) | PDF, PPTX |
| 📰 | Document | Reports, proposals | Documentation (📚) | PDF, DOCX |
| 🎬 | Video | Animations, ads | Marketing (📣) | MP4, GIF |
| 🖼️ | Graphic | Logos, icons, banners | Design (🎨) | PNG, SVG |
| 📧 | Email | Newsletters, campaigns | Marketing (📣) | HTML, PNG |
| 🌐 | Web | Banners, headers | Marketing (📣) | PNG, SVG |
| 📊 | Infographic | Data visualization | Platform (🛣️) | PNG, PDF |
| 🎯 | Marketing | Flyers, posters | Marketing (📣) | PDF, PNG |
| 👕 | Print | Merch, business cards | Marketing (📣) | PDF, PNG |

---

## 🏷️ Canva Asset Types as GreenLight Tags

| Asset Type | Emoji | GreenLight Usage | Examples |
|------------|-------|------------------|----------|
| Image | 🖼️ | Visual content | Photos, illustrations |
| Video | 🎬 | Motion content | Clips, animations |
| Audio | 🎵 | Sound content | Music, voiceovers |
| Text | 📝 | Typography | Headings, body text |
| Shape | 🔷 | Geometric | Rectangles, circles |
| Sticker | ✨ | Decorative | Icons, emojis |
| Chart | 📊 | Data viz | Bar, pie, line charts |
| Frame | 🖼️ | Containers | Image placeholders |
| Line | 📏 | Dividers | Horizontal, vertical |
| Grid | ⊞ | Layout | Structure, alignment |

---

## 🎨 Composite Patterns for Canva

### Design Operations
```
⚡🎨👉📌 = New design created, micro scale
✏️🎨🎢⭐ = Design edited, macro scale, high priority
🎉🎨🎢🌍 = Design published, macro impact
```

### Asset Operations
```
📤🖼️👉📌 = Image uploaded
🎬📥👉📌 = Video imported
📊🎨🎢📌 = Chart/infographic created, macro
```

### Collaboration Events
```
💬🎨👉⭐ = Comment added, high priority
👥🎨👉📌 = Design shared with team
✅👍🎢📌 = Design approved, macro
```

### Export Operations
```
📦💾👉📌 = Design exported, micro
🌐🎨🎢🌍 = Design published to web, global
📱🎨👉📣 = Social media post published
```

### Full Canva Flow
```
[⚡🎨] [✏️🎨] [💬🎨] [✅👍] [🎉🎨] [📦💾] = Create → Edit → Review → Approve → Publish → Export
[📤🖼️] [⚙️✏️] [📱🎨] = Upload → Edit → Post to social
```

---

## 📝 NATS Subject Patterns (Canva)

### Design Events
```
greenlight.canva.design.created.micro.design.{design_id}
greenlight.canva.design.updated.micro.design.{design_id}
greenlight.canva.design.deleted.micro.design.{design_id}
greenlight.canva.design.published.macro.design.{design_id}
```

### Asset Events
```
greenlight.canva.asset.uploaded.micro.design.{asset_id}
greenlight.canva.asset.deleted.micro.design.{asset_id}
greenlight.canva.asset.replaced.micro.design.{asset_id}
```

### Export Events
```
greenlight.canva.export.started.micro.design.{design_id}
greenlight.canva.export.completed.macro.design.{design_id}
greenlight.canva.export.failed.micro.design.{design_id}
```

### Collaboration Events
```
greenlight.canva.comment.added.micro.design.{design_id}
greenlight.canva.share.invited.micro.design.{user_id}
greenlight.canva.approval.requested.micro.design.{design_id}
greenlight.canva.approval.granted.macro.design.{design_id}
```

### Folder Events
```
greenlight.canva.folder.created.micro.design.{folder_id}
greenlight.canva.folder.organized.micro.design.{folder_id}
```

---

## 🔨 Canva Memory Templates

### Design Operations

```bash
# Design created
gl_canva_design_created() {
    local design_title="$1"
    local design_type="$2"  # social_post, presentation, document, video, etc.
    local creator="${3:-unknown}"

    local type_emoji=""
    case "$design_type" in
        social_post|instagram|facebook|twitter) type_emoji="📱" ;;
        presentation|slides) type_emoji="📄" ;;
        document|report) type_emoji="📰" ;;
        video|animation) type_emoji="🎬" ;;
        graphic|logo|icon) type_emoji="🖼️" ;;
        email|newsletter) type_emoji="📧" ;;
        infographic|chart) type_emoji="📊" ;;
        *) type_emoji="🎨" ;;
    esac

    gl_log "⚡${type_emoji}👉📌" \
        "design_created" \
        "$design_title" \
        "Type: $design_type, Creator: $creator"
}

# Design edited
gl_canva_design_edited() {
    local design_title="$1"
    local edit_type="${2:-content}"  # content, layout, style, text

    local edit_emoji=""
    case "$edit_type" in
        content) edit_emoji="✏️" ;;
        layout) edit_emoji="⊞" ;;
        style) edit_emoji="🎨" ;;
        text) edit_emoji="📝" ;;
        *) edit_emoji="⚙️" ;;
    esac

    gl_log "${edit_emoji}🎨👉📌" \
        "design_edited" \
        "$design_title" \
        "Edit type: $edit_type"
}

# Template used
gl_canva_template_used() {
    local template_name="$1"
    local design_title="$2"
    local category="${3:-general}"

    gl_log "📥🖼️👉📌" \
        "template_used" \
        "$template_name" \
        "For: $design_title, Category: $category"
}

# Design published
gl_canva_design_published() {
    local design_title="$1"
    local platform="${2:-web}"  # web, instagram, facebook, etc.
    local url="${3:-}"

    local platform_emoji=""
    case "$platform" in
        web) platform_emoji="🌐" ;;
        instagram) platform_emoji="📱" ;;
        facebook) platform_emoji="📘" ;;
        twitter) platform_emoji="🐦" ;;
        linkedin) platform_emoji="💼" ;;
        *) platform_emoji="🎨" ;;
    esac

    gl_log "🎉${platform_emoji}🎢🌍" \
        "design_published" \
        "$design_title" \
        "Platform: $platform, URL: $url"
}

# Design deleted
gl_canva_design_deleted() {
    local design_title="$1"
    local reason="${2:-user_action}"

    gl_log "🗑️🎨👉📌" \
        "design_deleted" \
        "$design_title" \
        "Reason: $reason"
}
```

### Asset Operations

```bash
# Asset uploaded
gl_canva_asset_uploaded() {
    local asset_type="$1"  # image, video, audio
    local asset_name="$2"
    local size="${3:-unknown}"

    local asset_emoji=""
    case "$asset_type" in
        image|photo) asset_emoji="🖼️" ;;
        video|clip) asset_emoji="🎬" ;;
        audio|sound) asset_emoji="🎵" ;;
        *) asset_emoji="📤" ;;
    esac

    gl_log "📤${asset_emoji}👉📌" \
        "asset_uploaded" \
        "$asset_name" \
        "Type: $asset_type, Size: $size"
}

# Asset replaced
gl_canva_asset_replaced() {
    local old_asset="$1"
    local new_asset="$2"
    local design_title="$3"

    gl_log "🔄🖼️👉📌" \
        "asset_replaced" \
        "$design_title" \
        "$old_asset → $new_asset"
}

# Brand kit asset used
gl_canva_brand_asset_used() {
    local asset_name="$1"
    local asset_type="$2"  # logo, color, font
    local design_title="$3"

    local brand_emoji=""
    case "$asset_type" in
        logo) brand_emoji="🏷️" ;;
        color) brand_emoji="🎨" ;;
        font) brand_emoji="🔤" ;;
        *) brand_emoji="🎯" ;;
    esac

    gl_log "${brand_emoji}🎨👉📌" \
        "brand_asset_used" \
        "$asset_name" \
        "In: $design_title, Type: $asset_type"
}
```

### Export Operations

```bash
# Export started
gl_canva_export_started() {
    local design_title="$1"
    local format="$2"  # PNG, JPG, PDF, MP4, GIF, SVG
    local quality="${3:-standard}"

    gl_log "⏳📦👉📌" \
        "export_started" \
        "$design_title" \
        "Format: $format, Quality: $quality"
}

# Export completed
gl_canva_export_completed() {
    local design_title="$1"
    local format="$2"
    local file_size="$3"
    local duration="${4:-unknown}"

    local format_emoji=""
    case "$format" in
        PNG|JPG|JPEG) format_emoji="🖼️" ;;
        PDF) format_emoji="📄" ;;
        MP4|MOV) format_emoji="🎬" ;;
        GIF) format_emoji="🎞️" ;;
        SVG) format_emoji="🎨" ;;
        *) format_emoji="📦" ;;
    esac

    gl_log "✅${format_emoji}🎢📌" \
        "export_completed" \
        "$design_title" \
        "Format: $format, Size: $file_size, Duration: $duration"
}

# Export failed
gl_canva_export_failed() {
    local design_title="$1"
    local format="$2"
    local error="${3:-unknown error}"

    gl_log "❌📦👉🔥" \
        "export_failed" \
        "$design_title" \
        "Format: $format, Error: $error"
}
```

### Collaboration Operations

```bash
# Comment added
gl_canva_comment_added() {
    local design_title="$1"
    local commenter="$2"
    local preview="${3:0:50}"

    gl_log "💬🎨👉⭐" \
        "comment_added" \
        "$design_title" \
        "$commenter: $preview..."
}

# Design shared
gl_canva_design_shared() {
    local design_title="$1"
    local shared_with="$2"
    local permission="${3:-view}"  # view, edit, comment

    gl_log "👥🎨👉📌" \
        "design_shared" \
        "$design_title" \
        "With: $shared_with, Permission: $permission"
}

# Approval requested
gl_canva_approval_requested() {
    local design_title="$1"
    local requester="$2"
    local approvers="$3"

    gl_log "🔔✅👉⭐" \
        "approval_requested" \
        "$design_title" \
        "By: $requester, Approvers: $approvers"
}

# Approval granted
gl_canva_approval_granted() {
    local design_title="$1"
    local approver="$2"
    local feedback="${3:-approved}"

    gl_log "✅👍🎢📌" \
        "approval_granted" \
        "$design_title" \
        "By: $approver, Feedback: $feedback"
}

# Approval rejected
gl_canva_approval_rejected() {
    local design_title="$1"
    local approver="$2"
    local reason="${3:-needs changes}"

    gl_log "❌👎👉🔥" \
        "approval_rejected" \
        "$design_title" \
        "By: $approver, Reason: $reason"
}
```

### Folder Operations

```bash
# Folder created
gl_canva_folder_created() {
    local folder_name="$1"
    local parent="${2:-root}"

    gl_log "📁➕👉📌" \
        "folder_created" \
        "$folder_name" \
        "Parent: $parent"
}

# Design moved to folder
gl_canva_design_moved() {
    local design_title="$1"
    local from_folder="$2"
    local to_folder="$3"

    gl_log "📁🔄👉📌" \
        "design_moved" \
        "$design_title" \
        "$from_folder → $to_folder"
}
```

### Brand Operations

```bash
# Brand kit updated
gl_canva_brand_kit_updated() {
    local brand_name="$1"
    local update_type="$2"  # logo, colors, fonts, templates
    local details="$3"

    local update_emoji=""
    case "$update_type" in
        logo) update_emoji="🏷️" ;;
        colors) update_emoji="🎨" ;;
        fonts) update_emoji="🔤" ;;
        templates) update_emoji="🖼️" ;;
        *) update_emoji="🎯" ;;
    esac

    gl_log "${update_emoji}🎯🎢📌" \
        "brand_kit_updated" \
        "$brand_name" \
        "Updated: $update_type - $details"
}
```

---

## 🎯 Example Integration: Complete Canva Workflow

### Scenario: Social media post creation and publishing

```bash
# 1. Design created from template
gl_canva_template_used "Instagram Story - Tech Product" "BlackRoad OS Launch" "social_media"
# [📥🖼️👉📌] template_used: Instagram Story - Tech Product — For: BlackRoad OS Launch, Category: social_media

gl_canva_design_created "BlackRoad OS Launch" "instagram" "alexa"
# [⚡📱👉📌] design_created: BlackRoad OS Launch — Type: instagram, Creator: alexa

# 2. Brand assets used
gl_canva_brand_asset_used "BlackRoad Logo" "logo" "BlackRoad OS Launch"
# [🏷️🎨👉📌] brand_asset_used: BlackRoad Logo — In: BlackRoad OS Launch, Type: logo

gl_canva_brand_asset_used "Brand Purple" "color" "BlackRoad OS Launch"
# [🎨🎨👉📌] brand_asset_used: Brand Purple — In: BlackRoad OS Launch, Type: color

# 3. Custom image uploaded
gl_canva_asset_uploaded "image" "product-screenshot.png" "2.4MB"
# [📤🖼️👉📌] asset_uploaded: product-screenshot.png — Type: image, Size: 2.4MB

# 4. Design edited
gl_canva_design_edited "BlackRoad OS Launch" "content"
# [✏️🎨👉📌] design_edited: BlackRoad OS Launch — Edit type: content

gl_canva_design_edited "BlackRoad OS Launch" "text"
# [📝🎨👉📌] design_edited: BlackRoad OS Launch — Edit type: text

# 5. Comment from team member
gl_canva_comment_added "BlackRoad OS Launch" "designer" "Love the color scheme! Maybe adjust the headline size?"
# [💬🎨👉⭐] comment_added: BlackRoad OS Launch — designer: Love the color scheme! Maybe adjust the headline size?...

# 6. Approval requested
gl_canva_approval_requested "BlackRoad OS Launch" "alexa" "marketing-team"
# [🔔✅👉⭐] approval_requested: BlackRoad OS Launch — By: alexa, Approvers: marketing-team

# 7. Approval granted
gl_canva_approval_granted "BlackRoad OS Launch" "marketing-lead" "Looks great! Ready to post"
# [✅👍🎢📌] approval_granted: BlackRoad OS Launch — By: marketing-lead, Feedback: Looks great! Ready to post

# 8. Export as PNG
gl_canva_export_started "BlackRoad OS Launch" "PNG" "high"
# [⏳📦👉📌] export_started: BlackRoad OS Launch — Format: PNG, Quality: high

gl_canva_export_completed "BlackRoad OS Launch" "PNG" "4.2MB" "2.1s"
# [✅🖼️🎢📌] export_completed: BlackRoad OS Launch — Format: PNG, Size: 4.2MB, Duration: 2.1s

# 9. Published to Instagram
gl_canva_design_published "BlackRoad OS Launch" "instagram" "https://instagram.com/p/abc123"
# [🎉📱🎢🌍] design_published: BlackRoad OS Launch — Platform: instagram, URL: https://instagram.com/p/abc123
```

### Scenario: Presentation deck creation

```bash
# 1. New presentation created
gl_canva_design_created "Q4 Business Review" "presentation" "alexa"
# [⚡📄👉📌] design_created: Q4 Business Review — Type: presentation, Creator: alexa

# 2. Chart added for data visualization
gl_canva_asset_uploaded "chart" "revenue-chart.svg" "124KB"
# [📤📊👉📌] asset_uploaded: revenue-chart.svg — Type: chart, Size: 124KB

# 3. Multiple edits
gl_canva_design_edited "Q4 Business Review" "layout"
# [⊞🎨👉📌] design_edited: Q4 Business Review — Edit type: layout

gl_canva_design_edited "Q4 Business Review" "content"
# [✏️🎨👉📌] design_edited: Q4 Business Review — Edit type: content

# 4. Shared with team for collaboration
gl_canva_design_shared "Q4 Business Review" "exec-team" "edit"
# [👥🎨👉📌] design_shared: Q4 Business Review — With: exec-team, Permission: edit

# 5. Team adds comments
gl_canva_comment_added "Q4 Business Review" "cfo" "Update slide 5 with latest metrics"
# [💬🎨👉⭐] comment_added: Q4 Business Review — cfo: Update slide 5 with latest metrics...

# 6. Export as PDF
gl_canva_export_started "Q4 Business Review" "PDF" "standard"
# [⏳📦👉📌] export_started: Q4 Business Review — Format: PDF, Quality: standard

gl_canva_export_completed "Q4 Business Review" "PDF" "8.7MB" "4.5s"
# [✅📄🎢📌] export_completed: Q4 Business Review — Format: PDF, Size: 8.7MB, Duration: 4.5s
```

### Scenario: Brand kit update

```bash
# 1. Brand kit updated with new logo
gl_canva_brand_kit_updated "BlackRoad OS" "logo" "Added vertical logo variant"
# [🏷️🎯🎢📌] brand_kit_updated: BlackRoad OS — Updated: logo - Added vertical logo variant

# 2. Brand colors updated
gl_canva_brand_kit_updated "BlackRoad OS" "colors" "Added accent gradient: #FF9D00 to #FF0066"
# [🎨🎯🎢📌] brand_kit_updated: BlackRoad OS — Updated: colors - Added accent gradient: #FF9D00 to #FF0066

# 3. Brand fonts updated
gl_canva_brand_kit_updated "BlackRoad OS" "fonts" "Added Inter for body text"
# [🔤🎯🎢📌] brand_kit_updated: BlackRoad OS — Updated: fonts - Added Inter for body text
```

---

## 📊 Canva Integration Details

**API Version:** v1
**API Endpoint:** https://api.canva.com/rest/v1/
**OAuth Scopes:** design:content:read, design:content:write, asset:read, asset:write, folder:read, folder:write

### Recommended Folder Structure:

1. **Social Media** (📱)
   - Instagram Posts/Stories
   - Facebook Posts
   - Twitter/X Posts
   - LinkedIn Posts

2. **Marketing** (📣)
   - Ads (Google, Facebook, Instagram)
   - Email Newsletters
   - Landing Pages
   - Banners

3. **Brand Assets** (🎯)
   - Logos
   - Brand Guidelines
   - Templates
   - Icons

4. **Documents** (📄)
   - Presentations
   - Reports
   - Proposals
   - White Papers

5. **Video** (🎬)
   - Animations
   - Explainer Videos
   - Social Ads
   - Product Demos

---

## 📚 Integration Checklist

- [x] Mapped Canva events to GreenLight 27-step workflow
- [x] Created design-type-to-domain mappings
- [x] Defined asset types as GreenLight tags
- [x] Extended NATS subjects for Canva events
- [x] Built 15+ Canva-specific templates
- [x] Design lifecycle tracking
- [x] Asset upload/replace operations
- [x] Export operations (PNG, PDF, MP4, SVG)
- [x] Collaboration and approval workflows
- [x] Comment tracking
- [x] Folder organization
- [x] Brand kit management
- [x] Template usage tracking

---

**Created:** December 23, 2025
**For:** Canva Design Workflow Integration
**Version:** 2.0.0-canva
**Status:** 🔨 IMPLEMENTATION

