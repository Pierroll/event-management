# Design System Inspired by Eventbrite

## 1. Visual Theme & Atmosphere

Eventbrite's design system embodies a modern, accessible approach to event discovery and ticketing. The aesthetic balances professional sophistication with approachable friendliness, using a refined color palette anchored by deep plum and electric blue tones. The design prioritizes clarity and usability with generous whitespace, rounded interactions, and clear information hierarchy. Typography is bold and confident, drawing from geometric sans-serif foundations. The overall atmosphere is inviting yet authoritative—designed to make event discovery feel both exciting and trustworthy, whether users are exploring local concerts, conferences, or community gatherings.

**Key Characteristics**
- Deep, sophisticated plum and gray neutrals as primary anchors
- Vibrant electric blue for interactive and call-to-action elements
- Warm coral-orange accent for emphasis and secondary actions
- Generous whitespace and breathing room between components
- Rounded, soft interactive elements (buttons, cards)
- Geometric, modern sans-serif typography (Neue Plak family)
- Clean information hierarchy with strong visual separation
- Accessibility-first approach with ample contrast and touch targets

## 2. Color Palette & Roles

### Primary
- **Deep Plum** (`#39364F`): Primary text, UI foundation, and dominant brand color used throughout the interface
- **Electric Blue** (`#3659E3`): Primary call-to-action, interactive elements, links, and engagement drivers
- **Bright Blue** (`#3D64FF`): Secondary bright interactive state and hover elevations

### Accent Colors
- **Coral Orange** (`#F05537`): Secondary actions, event highlights, and emphasis elements
- **Navy Blue** (`#304FC9`): Interactive states and secondary brand emphasis

### Interactive
- **Hyperlink Blue** (`#3659E3`): Links and primary interactions
- **Secondary State Blue** (`#3D64FF`): Hover and focused interactive elements
- **Button Border** (`#DEEEFF`): Card and input borders with blue tint

### Neutral Scale
- **White** (`#FFFFFF`): Background surfaces and card bases
- **Light Lavender** (`#F8F7FA`): Subtle background tint for secondary surfaces
- **Pale Lavender** (`#EEEDF2`): Tertiary background and divider surfaces
- **Gray-Purple** (`#A9A8B3`): Placeholder text and disabled states
- **Light Divider** (`#DBDAE3`): Subtle borders and dividers
- **Light Gray** (`#EFEFEF`): Minimal border emphasis
- **Charcoal Gray** (`#585163`): Secondary body text and supporting copy
- **Mid-Tone Gray** (`#6F7287`): Tertiary text and muted labels
- **Slate Gray** (`#4B4D63`): Supporting text and secondary information

### Surface & Borders
- **White** (`#FFFFFF`): Primary card and input backgrounds
- **Pale Lavender** (`#EEEDF2`): Secondary surface backgrounds
- **Light Lavender** (`#F8F7FA`): Tertiary surface backgrounds
- **Light Divider** (`#DBDAE3`): Default border color for containers

### Semantic / Status
- **Critical Red** (`#D1410C`): Error states and critical alerts
- **Error Dark** (`#C23C0C`): Darker error variant for emphasis
- **Alert Red** (`#C5162E`): Alternative error state
- **Danger Magenta** (`#E02E46`): High-priority error messaging

## 3. Typography Rules

### Font Family
**Primary Font:** Neue Plak
- Font stack: `Neue Plak, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`
- Used for headings, labels, buttons, and primary UI text

**Secondary Font:** Neue Plak Text
- Font stack: `Neue Plak Text, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`
- Used for body copy, supplementary text, and refined typography

### Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
|------|------|------|--------|-------------|----------------|-------|
| Display | Neue Plak | 32px | 700 | 40px | 0px | Hero headlines and large promotions |
| Heading 1 (h1) | Neue Plak | 24px | 600 | 32px | 0px | Page titles and major sections |
| Heading 2 (h2) | Neue Plak | 20px | 700 | 28px | 0px | Subsection titles and card headers |
| Heading 3 (h3) | Neue Plak | 18px | 600 | 24px | 0px | Section headers and labels |
| Body Large | Neue Plak | 16px | 400 | 22px | 0px | Primary body text and descriptions |
| Body Regular | Neue Plak Text | 14px | 600 | 20px | 0px | Secondary body and supporting text |
| Body Small | Neue Plak | 12px | 600 | 16px | 0px | Captions, metadata, and timestamps |
| Button | Neue Plak | 16px | 400 | 20px | 0px | Button labels and calls-to-action |
| Link | Neue Plak Text | 14px | 600 | 20px | 0px | Hyperlinks and navigation items |
| Label | Neue Plak Text | 12px | 600 | 16px | 0px | Form labels and badges |
| Code | Neue Plak | 12px | 400 | 16px | 0px | Code blocks and technical text |

### Principles
- **Hierarchy through weight, not just size:** Use `600px` and `700px` weights for prominence; `400px` for recessive content
- **Line height breathing:** Maintain 1.2–1.4x line height multipliers for comfortable reading
- **Consistent letter spacing:** All typography uses `0px` letter spacing for modern, tightly-kerned appearance
- **Geometric sans-serif preference:** Neue Plak's geometric forms convey modernity and approachability
- **Size discretion:** Limit to 5 distinct font sizes to maintain system cohesion
- **Contrast for accessibility:** Ensure all body text meets WCAG AA standards against backgrounds
- **Emphasis via style, not color alone:** Combine weight, size, and color for redundant encoding of hierarchy

## 4. Component Stylings

### Buttons

#### Primary Button
- **Background:** `#3659E3`
- **Text Color:** `#FFFFFF`
- **Font:** Neue Plak, `16px`, weight `400`
- **Padding:** `12px 24px`
- **Border Radius:** `360px`
- **Border:** `0px`
- **Line Height:** `20px`
- **Hover:** Background `#304FC9`, shadow `rgba(40, 44, 53, 0.15) 0px 4px 12px`
- **Active:** Background `#2A3BA8`
- **Disabled:** Background `#A9A8B3`, text `#FFFFFF`, opacity `0.6`

#### Secondary Button
- **Background:** `#FFFFFF`
- **Text Color:** `#39364F`
- **Font:** Neue Plak, `16px`, weight `400`
- **Padding:** `12px 24px`
- **Border Radius:** `360px`
- **Border:** `2px solid #DBDAE3`
- **Line Height:** `20px`
- **Hover:** Background `#F8F7FA`, border `#A9A8B3`
- **Active:** Background `#EEEDF2`, border `#585163`
- **Disabled:** Background `#FFFFFF`, text `#A9A8B3`, border `#EFEFEF`

#### Ghost Button (Text-only)
- **Background:** `transparent`
- **Text Color:** `#3659E3`
- **Font:** Neue Plak, `16px`, weight `400`
- **Padding:** `8px 0px`
- **Border Radius:** `0px`
- **Border:** `0px`
- **Line Height:** `20px`
- **Hover:** Text color `#304FC9`, text-decoration `underline`
- **Active:** Text color `#2A3BA8`
- **Disabled:** Text color `#A9A8B3`

#### Icon Button
- **Background:** `transparent`
- **Text Color:** `#39364F`
- **Font:** Neue Plak, `16px`, weight `400`
- **Padding:** `8px`
- **Height:** `40px`
- **Width:** `40px`
- **Border Radius:** `50%`
- **Border:** `0px`
- **Hover:** Background `#F8F7FA`
- **Active:** Background `#EEEDF2`
- **Disabled:** Color `#A9A8B3`, opacity `0.5`

#### Floating Action Button
- **Background:** `#F05537`
- **Text Color:** `#FFFFFF`
- **Font:** Neue Plak, `16px`, weight `600`
- **Height:** `56px`
- **Width:** `56px`
- **Border Radius:** `50%`
- **Border:** `0px`
- **Shadow:** `rgba(240, 85, 55, 0.25) 0px 8px 16px`
- **Hover:** Background `#D6441F`, shadow `rgba(240, 85, 55, 0.35) 0px 12px 24px`

### Cards & Containers

#### Event Card
- **Background:** `#FFFFFF`
- **Border:** `1px solid #DBDAE3`
- **Border Radius:** `12px 12px 12px 12px`
- **Padding:** `0px`
- **Shadow:** `rgba(40, 44, 53, 0.08) 0px 2px 8px`
- **Hover:** Border `#3659E3`, shadow `rgba(40, 44, 53, 0.12) 0px 4px 16px`
- **Image Container:** Border radius `40px 40px 0px 0px`, overflow `hidden`
- **Content Padding:** `16px`

#### Category Icon Card
- **Background:** `#FFFFFF`
- **Border:** `1px solid #DEEEFF`
- **Border Radius:** `50%`
- **Height:** `107px`
- **Width:** `107px`
- **Padding:** `0px`
- **Icon Color:** `#3659E3`
- **Hover:** Background `#F8F7FA`, border `#3659E3`
- **Active:** Background `#EEEDF2`

#### Surface Container
- **Background:** `#F8F7FA`
- **Border:** `0px`
- **Border Radius:** `8px`
- **Padding:** `24px`
- **Shadow:** `none`

#### Elevated Surface
- **Background:** `#FFFFFF`
- **Border:** `1px solid #DBDAE3`
- **Border Radius:** `8px`
- **Padding:** `24px`
- **Shadow:** `rgba(40, 44, 53, 0.1) 0px 1px 20px, rgba(40, 44, 53, 0.1) 0px 2px 5px`

### Inputs & Forms

#### Text Input
- **Background:** `#FFFFFF`
- **Text Color:** `#39364F`
- **Font:** Neue Plak, `16px`, weight `400`
- **Padding:** `12px 12px`
- **Border:** `1px solid #DBDAE3`
- **Border Radius:** `4px`
- **Height:** `44px`
- **Line Height:** `22px`
- **Placeholder:** `#A9A8B3`
- **Focus:** Border `#3659E3`, shadow `rgba(54, 89, 227, 0.1) 0px 0px 0px 3px`
- **Error:** Border `#D1410C`, background `rgba(209, 65, 12, 0.05)`
- **Disabled:** Background `#EEEDF2`, text `#A9A8B3`, border `#EFEFEF`

#### Search Input
- **Background:** `#FFFFFF`
- **Text Color:** `#39364F`
- **Font:** Neue Plak, `16px`, weight `400`
- **Padding:** `12px 8px 12px 16px`
- **Border:** `1px solid #DBDAE3`
- **Border Radius:** `4px`
- **Height:** `44px`
- **Icon Color:** `#F05537`
- **Placeholder:** `#A9A8B3`, `"Search..."`
- **Focus:** Border `#3659E3`, shadow `rgba(54, 89, 227, 0.1) 0px 0px 0px 3px`

#### Location Input
- **Background:** `#FFFFFF`
- **Text Color:** `#39364F`
- **Font:** Neue Plak, `16px`, weight `400`
- **Padding:** `12px 8px 12px 16px`
- **Border:** `1px solid #DBDAE3`
- **Border Radius:** `4px`
- **Height:** `44px`
- **Icon Color:** `#39364F`
- **Placeholder:** `#A9A8B3`, `"Location..."`
- **Focus:** Border `#3659E3`

#### Form Label
- **Font:** Neue Plak Text, `12px`, weight `600`
- **Color:** `#39364F`
- **Line Height:** `16px`
- **Margin Bottom:** `8px`
- **Required Indicator:** Color `#D1410C`

#### Checkbox
- **Size:** `18px × 18px`
- **Border:** `2px solid #DBDAE3`
- **Border Radius:** `4px`
- **Background:** `#FFFFFF`
- **Checked Background:** `#3659E3`
- **Checked Icon Color:** `#FFFFFF`
- **Hover:** Border `#3659E3`
- **Disabled:** Border `#EFEFEF`, background `#EEEDF2`

#### Radio Button
- **Size:** `18px × 18px`
- **Border:** `2px solid #DBDAE3`
- **Border Radius:** `50%`
- **Background:** `#FFFFFF`
- **Selected Inner Circle:** `#3659E3`, diameter `10px`
- **Hover:** Border `#3659E3`
- **Disabled:** Border `#EFEFEF`, background `#EEEDF2`

### Navigation

#### Top Navigation Bar
- **Background:** `#FFFFFF`
- **Height:** `64px`
- **Border Bottom:** `1px solid #DBDAE3`
- **Padding:** `0px 24px`
- **Shadow:** `rgba(40, 44, 53, 0.08) 0px 2px 8px`

#### Navigation Link
- **Font:** Neue Plak, `16px`, weight `400`
- **Color:** `#39364F`
- **Padding:** `12px 16px`
- **Border Radius:** `0px`
- **Line Height:** `20px`
- **Hover:** Color `#3659E3`, background `transparent`
- **Active:** Color `#3659E3`, border-bottom `2px solid #3659E3`
- **Disabled:** Color `#A9A8B3`

#### Dropdown Menu
- **Background:** `#FFFFFF`
- **Border:** `1px solid #DBDAE3`
- **Border Radius:** `8px`
- **Padding:** `8px 0px`
- **Shadow:** `rgba(40, 44, 53, 0.1) 0px 1px 20px, rgba(40, 44, 53, 0.1) 0px 2px 5px`
- **Dropdown Item:** Font Neue Plak `14px` weight `400`, padding `12px 16px`, hover background `#F8F7FA`

#### Breadcrumb
- **Font:** Neue Plak Text, `12px`, weight `600`
- **Color:** `#585163`
- **Separator:** `#A9A8B3`, content `"/"`
- **Active Link:** Color `#3659E3`
- **Gap:** `8px`

### Badges & Status Indicators

#### Badge (Default)
- **Background:** `#EEEDF2`
- **Text Color:** `#39364F`
- **Font:** Neue Plak Text, `12px`, weight `600`
- **Padding:** `4px 8px`
- **Border Radius:** `12px`
- **Line Height:** `16px`

#### Badge (Primary)
- **Background:** `rgba(54, 89, 227, 0.1)`
- **Text Color:** `#3659E3`
- **Font:** Neue Plak Text, `12px`, weight `600`
- **Padding:** `4px 8px`
- **Border Radius:** `12px`

#### Badge (Success)
- **Background:** `rgba(34, 197, 94, 0.1)`
- **Text Color:** `#22C55E`
- **Font:** Neue Plak Text, `12px`, weight `600`
- **Padding:** `4px 8px`
- **Border Radius:** `12px`

#### Badge (Error)
- **Background:** `rgba(209, 65, 12, 0.1)`
- **Text Color:** `#D1410C`
- **Font:** Neue Plak Text, `12px`, weight `600`
- **Padding:** `4px 8px`
- **Border Radius:** `12px`

### Tabs

#### Tab Container
- **Background:** `#FFFFFF`
- **Border Bottom:** `1px solid #DBDAE3`
- **Height:** `48px`
- **Padding:** `0px 24px`

#### Tab Item
- **Font:** Neue Plak Text, `14px`, weight `600`
- **Color:** `#585163`
- **Padding:** `12px 16px`
- **Border Radius:** `0px`
- **Border Bottom:** `2px solid transparent`
- **Hover:** Color `#39364F`
- **Active:** Color `#3659E3`, border-bottom `2px solid #3659E3`
- **Disabled:** Color `#A9A8B3`, opacity `0.5`

### Alerts & Notifications

#### Alert (Info)
- **Background:** `rgba(54, 89, 227, 0.08)`
- **Border:** `1px solid rgba(54, 89, 227, 0.3)`
- **Border Radius:** `8px`
- **Padding:** `12px 16px`
- **Text Color:** `#304FC9`
- **Font:** Neue Plak Text, `14px`, weight `600`
- **Icon Color:** `#3659E3`

#### Alert (Error)
- **Background:** `rgba(209, 65, 12, 0.08)`
- **Border:** `1px solid rgba(209, 65, 12, 0.3)`
- **Border Radius:** `8px`
- **Padding:** `12px 16px`
- **Text Color:** `#D1410C`
- **Font:** Neue Plak Text, `14px`, weight `600`
- **Icon Color:** `#D1410C`

#### Alert (Warning)
- **Background:** `rgba(240, 85, 55, 0.08)`
- **Border:** `1px solid rgba(240, 85, 55, 0.3)`
- **Border Radius:** `8px`
- **Padding:** `12px 16px`
- **Text Color:** `#F05537`
- **Font:** Neue Plak Text, `14px`, weight `600`
- **Icon Color:** `#F05537`

## 5. Layout Principles

### Spacing System

**Base Unit:** `4px`

**Scale:**
- `4px`: Minimal gap (icon spacing, tight lists)
- `8px`: Compact padding (form field internals, tight components)
- `12px`: Small padding (button internals, small containers)
- `16px`: Standard padding (card content, default spacing)
- `24px`: Medium padding (section padding, component groups)
- `36px`: Large padding (major section spacing)
- `40px`: Extra-large padding (hero sections, page containers)
- `48px`: XL padding (full section separation)
- `56px`: Component gap (large list/grid spacing)
- `76px`: Major section gap
- `80px`: Page-level vertical rhythm

**Usage Context:**
- **Button padding:** `12px 24px` (inner) / `8px 16px` (compact)
- **Card padding:** `16px` (content), `24px` (large cards)
- **Section margins:** `48px` (between sections), `80px` (between major blocks)
- **Form spacing:** `12px` (label-to-input), `16px` (field-to-field)
- **List/grid gaps:** `16px` (standard), `24px` (relaxed)

### Grid & Container

**Max Width:** `1200px` (primary content area)

**Column Strategy:**
- Desktop: 12-column grid with `16px` gutters
- Tablet: 8-column grid with `16px` gutters
- Mobile: Single-column layout with `16px` side margins

**Container Widths:**
- Full width: `100%`
- Wide container: `1200px`
- Standard container: `960px`
- Narrow container: `640px`

**Section Patterns:**
- **Hero section:** Full viewport width, vertical center with `80px` padding top/bottom
- **Content section:** Centered container with `48px` top/bottom padding
- **List/grid section:** Centered container with `24px` grid gap
- **Footer:** Full width with `2–3` column layout on desktop, single column on mobile

### Whitespace Philosophy

Eventbrite's layout prioritizes breathing room over density. Generous vertical spacing between sections creates visual rest and emphasizes content hierarchy. Horizontal padding is consistent (`24px` on desktop, `16px` on mobile) to provide edge cushioning without feeling cramped. Components maintain internal breathing via `12px–16px` padding to avoid content collapse. Whitespace is used functionally—to separate distinct content blocks, create visual grouping, and guide the eye through information hierarchy without requiring additional borders or dividers.

### Border Radius Scale

- **Minimal:** `0px` (text links, some buttons, navigation)
- **Sharp:** `4px` (form inputs, tabs, small alerts)
- **Standard:** `8px` (cards, containers, dropdowns, moderately rounded)
- **Rounded:** `12px` (badges, chips, smaller cards)
- **Very Rounded:** `40px` (top corners of modal images)
- **Fully Rounded:** `50%` (circular buttons, icon buttons, category cards, full circles)
- **Pill-shaped:** `360px` (primary buttons, full-width pill buttons)

## 6. Depth & Elevation

| Level | Treatment | Use |
|-------|-----------|-----|
| **Flat** | No shadow, border `1px solid #DBDAE3` | Base UI, disabled states, text elements |
| **Raised** | `rgba(40, 44, 53, 0.08) 0px 2px 8px 0px` | Cards, containers, subtle elevation |
| **Elevated** | `rgba(40, 44, 53, 0.1) 0px 1px 20px 0px, rgba(40, 44, 53, 0.1) 0px 2px 5px 0px` | Dropdowns, modals, floating panels |
| **Floating** | `rgba(240, 85, 55, 0.25) 0px 8px 16px 0px` | Floating action buttons, prominent overlays |
| **High** | `rgba(40, 44, 53, 0.15) 0px 12px 24px 0px` | Toasts, notifications, highest-priority elements |

**Shadow Philosophy:** Eventbrite employs a restrained shadow system. Shadows are subtle and strictly functional—they indicate elevation and interactivity without creating visual noise. Shadows use dark, desaturated colors (`rgba(40, 44, 53, ...)`) at low opacity (`0.08–0.15`) to maintain visual clarity. Most UI elements use flat design with borders; shadows are reserved for floating or temporarily elevated components (dropdowns, modals, toasts). This approach maintains a clean, modern aesthetic while providing clear spatial hierarchy cues.

## 7. Do's and Don'ts

### Do

- **Do use `#3659E3` for all primary interactions** — buttons, links, active states, focus indicators. It's the brand's engagement color.
- **Do maintain `40px` minimum touch target size** for buttons and interactive elements on mobile devices.
- **Do pair dark plum text (`#39364F`) with white or light lavender backgrounds** for maximum contrast and readability.
- **Do use `12px–16px` padding inside components** to avoid visual cramping and improve touch usability.
- **Do apply rounded corners (`8px–12px`) to cards and containers** for a modern, approachable feel.
- **Do use Neue Plak for headings and primary UI; Neue Plak Text for body and supporting copy** to maintain typographic consistency.
- **Do group related form fields with `12px` spacing** to create clear visual relationships.
- **Do use the light lavender (`#F8F7FA`) and pale lavender (`#EEEDF2`) for non-interactive backgrounds** to provide subtle visual separation without overwhelming the interface.
- **Do apply hover states with darker colors or slight background tints** — never remove interactive feedback.
- **Do use error red (`#D1410C`) exclusively for validation failures, errors, and critical alerts** — never for warnings or informational content.

### Don't

- **Don't use multiple shades of blue for interactive elements** — stick to `#3659E3` and `#304FC9` (hover state) to avoid confusion.
- **Don't apply shadows to inactive or disabled elements** — shadows indicate interactivity; disabled UI should be flat and muted.
- **Don't mix Neue Plak and Neue Plak Text in ways that blur their semantic distinction** — use Neue Plak for labels/headings, Neue Plak Text for body.
- **Don't create touch targets smaller than `40px × 40px`** on any interactive element (buttons, links, icons).
- **Don't use the coral orange (`#F05537`) for text or primary interactions** — reserve it for secondary CTAs and accents only.
- **Don't apply border-radius less than `4px`** — sharp corners feel dated and harsh in this modern system.
- **Don't mix multiple neutrals (`#585163`, `#6F7287`, `#4B4D63`) for body text** — pick one and use it consistently.
- **Don't add borders to buttons** unless they're secondary variants; primary buttons should be solid and confident.
- **Don't use opacity below `0.6` for disabled states** — elements below this threshold become too difficult to perceive.
- **Don't create custom colors** — always reference the palette. Consistency builds trust.

## 8. Responsive Behavior

### Breakpoints

| Name | Width | Key Changes |
|------|-------|-------------|
| **Mobile** | `320px–639px` | Single-column layout, `16px` side margins, full-width inputs, stacked navigation, font sizes reduced by `2px` |
| **Tablet** | `640px–1023px` | 2–3 column grid, `24px` margins, collapsible navigation, card layouts maintained, standard font sizes |
| **Desktop** | `1024px–1199px` | 3–4 column grid, `24px` gutters, full navigation visible, max-width containers, standard typography |
| **Wide Desktop** | `1200px+` | 4–6 column grid, centered `1200px` max-width container, full-featured layouts, generous spacing |

### Touch Targets

- **Minimum size:** `40px × 40px` (buttons, icon buttons, checkboxes, radio buttons)
- **Recommended size:** `48px × 48px` (mobile primary actions, mobile navigation items)
- **Minimum spacing between targets:** `8px` (to prevent accidental taps)
- **Text links:** Minimum `44px` line height to accommodate touch; add padding around text links in lists

### Collapsing Strategy

**Navigation:**
- Desktop: Horizontal menu bar with links visible
- Tablet: Horizontal menu with overflow hidden, "More" dropdown on right
- Mobile: Hidden hamburger menu (3-line icon), slides from left or bottom, full-screen overlay

**Layout:**
- Desktop: 3–4 column grid for event cards, full sidebar for filters
- Tablet: 2–3 column grid, collapsible filter sidebar (toggle button)
- Mobile: Single-column stacking, filters accessible via expandable accordion

**Forms:**
- Desktop: Multi-column layouts (e.g., 2 fields per row)
- Tablet: Transition to single-field layouts with flexible widths
- Mobile: 100% width single-column, labels above inputs

**Spacing:**
- Desktop: `80px` vertical section spacing, `24px` padding
- Tablet: `56px` vertical spacing, `20px` padding
- Mobile: `40px` vertical spacing, `16px` padding

**Typography:**
- Desktop: Full sizes (h2: `24px`, body: `16px`)
- Tablet: Slight reduction (h2: `22px`, body: `15px`)
- Mobile: Compact sizes (h2: `20px`, body: `14px`), maintain `1.4x` line height

**Images & Media:**
- Desktop: Full-sized images in cards (`300px × 200px`)
- Tablet: Reduced size (`280px × 180px`)
- Mobile: Full-width images with `2:1` aspect ratio, responsive scaling

## 9. Agent Prompt Guide

### Quick Color Reference

- **Primary CTA:** Electric Blue (`#3659E3`) — all primary actions, links, focus states
- **Secondary CTA:** Coral Orange (`#F05537`) — secondary buttons, floating actions, accent emphasis
- **Background (Light):** White (`#FFFFFF`) — card and input backgrounds
- **Background (Subtle):** Light Lavender (`#F8F7FA`) — secondary surfaces, subtle sections
- **Heading text:** Deep Plum (`#39364F`) — all h1–h3 headings, primary labels
- **Body text:** Deep Plum (`#39364F`) for primary, Charcoal Gray (`#585163`) for secondary
- **Disabled/Placeholder:** Gray-Purple (`#A9A8B3`) — placeholder text, disabled states, muted labels
- **Border:** Light Divider (`#DBDAE3`) — default borders, dividers, card edges
- **Error:** Critical Red (`#D1410C`) — validation failures, alerts, error messaging
- **Hover states:** Use next darker shade (e.g., `#304FC9` for blue hover) or `#F8F7FA` background tint

### Iteration Guide

1. **Color Rule:** Always use uppercase hex values from the provided palette. Never create custom colors or invent new shades. Map every semantic role (primary, secondary, disabled, error) to its exact palette match.

2. **Typography Rule:** Apply Neue Plak for all headings, labels, and buttons; Neue Plak Text for body copy and supporting text. Always use the specified font weight (`400` for body/buttons, `600`–`700` for headings) and exact pixel size from the hierarchy table.

3. **Spacing Rule:** Use only the defined spacing scale (`4px`, `8px`, `12px`, `16px`, `24px`, `36px`, `40px`, `48px`, `56px`, `76px`, `80px`). Never create arbitrary padding or margins. All component internals must follow the grid (`12px` form padding, `16px` card padding, etc.).

4. **Button Rule:** Primary buttons use `#3659E3` background with `#FFFFFF` text, `360px` border-radius (pill shape), and `12px 24px` padding. Secondary buttons use white background with `#39364F` text and `2px` border. All buttons must be at least `40px` tall and `44px` wide (minimum).

5. **Border Radius Rule:** Apply `0px` only to text-link buttons and navigation. Use `4px` for inputs and small alerts. Use `8px` for cards and containers. Use `12px` for badges. Use `50%` for circular elements. Use `360px` for pill buttons. Never use values between these defined steps.

6. **Input Rule:** All text inputs must have `1px solid #DBDAE3` border, `12px 12px` padding, `44px` minimum height, and `4px` border-radius. On focus, add `rgba(54, 89, 227, 0.1) 0px 0px 0px 3px` shadow. On error, change border to `#D1410C` and background to `rgba(209, 65, 12, 0.05)`.

7. **Shadow Rule:** Use shadows sparingly. Only apply to cards (raised: `rgba(40, 44, 53, 0.08) 0px 2px 8px`), dropdowns (elevated: `rgba(40, 44, 53, 0.1) 0px 1px 20px, rgba(40, 44, 53, 0.1) 0px 2px 5px`), and floating elements (floating: `rgba(240, 85, 55, 0.25) 0px 8px 16px`). Flat UI (borders only) is the default.

8. **Responsive Rule:** At mobile (`< 640px`), switch to single-column layouts, `16px` margins, collapsible navigation, and reduced font sizes (`-2px`). At tablet (`640px–1023px`), use 2–3 columns with `24px` gutters. At desktop (`1024px+`), center content in `1200px` max-width with full navigation. Always maintain `40px` minimum touch targets.

9. **Contrast Rule:** Always pair dark text (`#39364F`) with light backgrounds (`#FFFFFF`, `#F8F7FA`) or light text (`#FFFFFF`) with dark backgrounds. Never place mid-tone grays on light backgrounds. Verify all combinations meet WCAG AA contrast minimum (`4.5:1` for body, `3:1` for large text).

10. **Component Structure Rule:** Every component must follow this structure: semantic color + specific typography + exact padding/height + border/radius + hover/active state + accessibility attributes (aria-labels, focus rings). Do not assume defaults; specify every property explicitly.