# jekyll-theme-easy-wedding

Are you or a friend getting married? Do you want a quick way to make a **customizable** website? This is the theme for you! When I got married, I created a website to commemorate the occasion as well provide information to my guests. Then, I had a bunch of friends get married, and they wanted me to make them a site too. So, instead of making _basically_ the same site over and over, I decided to templatize it so that I just have to change the data in a yaml file.

Most of the original work is from https://github.com/cbaclig/wedding and is thanks to [@cbaclig](https://github.com/cbaclig).

## Local Development Environment Setup

### Prerequisites

- **Node.js** (v18 or higher) - [Download](https://nodejs.org/)
- **Ruby** (v3.2.11) [Download](https://www.ruby-lang.org/en/downloads/)
- **Bundler** - Install with: `gem install bundler`

### Initial Setup

1. Clone or download this repository
2. Navigate to the project directory:
   ```bash
   cd andrewandbluearegettingmarried.rsvp
   ```

3. Install dependencies:
   ```bash
   npm install --legacy-peer-deps
   bundle install
   ```

### Running the Development Server

Start the development environment with:

```bash
npm start
```

This command runs both webpack (for asset bundling) and Jekyll server concurrently. Your site will be available at **http://localhost:4000**

The development server includes:
- **Live reload**: Changes to files are automatically detected and the browser refreshes
- **Asset bundling**: Webpack watches your SCSS and JavaScript files
- **Jekyll build**: Pages and layouts are automatically regenerated

### Alternative Commands

- **Webpack only** (asset bundling): `npm run serve:webpack`
- **Jekyll only** (no asset watching): `npm run serve:jekyll`
- **Production build**: `npm run build`

## Project Structure

```
src/                    # Source files (what you edit)
├── _data/              # YAML configuration files
├── _includes/          # HTML components/partials
├── _layouts/           # Page layout templates
├── _webpack/           # Webpack entry points and styling
├── index.html          # Home page
├── events.html         # Events page
├── stag.html           # Stag/bachelor party page
└── encrypted/          # Password-protected page
assets/                 # Static assets (images, fonts)
build/                  # Generated output (do not edit)
```

## Usage Guide

### Creating a New Page

To add a new page to your website:

1. **Create a new HTML file** in the `src/` directory (e.g., `src/timeline.html`)

2. **Add front matter** at the top of the file to specify the layout and content:
   ```yaml
   ---
   layout: info
   title: Our Timeline
   billboard_image: assets/img/your-image.jpg
   image_position: center center
   include: timeline.html
   ---
   ```

3. **Reference the include** in your page:
   ```html
   {% if page.include %}
     {% include {{ page.include }} %}
   {% endif %}
   ```

4. **Create the include file** in `src/_includes/timeline.html` with your content

5. **Update navigation** in `src/_data/navigation.yml` to add a link to your new page (if desired)

### Understanding Templates (Layouts)

Layouts are reusable page templates stored in `src/_layouts/`. The project includes:

- **`default.html`** - Basic page layout with navigation and footer
- **`info.html`** - Page with a billboard image header and content area
- **`page.html`** - Standard page layout
- **`banner.html`** - Layout for banner/announcement pages
- **`under_construction.html`** - Coming soon page

### Using Layouts

Specify a layout in the front matter of your page:

```yaml
---
layout: info
title: Page Title
billboard_image: assets/img/header.jpg
include: my_content.html
---
```

The layout determines the overall structure of the page. All layouts have access to:
- Site-wide settings from `src/_data/settings.yml`
- Page-specific variables from front matter
- Reusable components from `src/_includes/`

### Configuration Files

Settings are stored as YAML in `src/_data/`:

- **`settings.yml`** - Global site settings (colors, RSVP settings, hero image)
- **`couple.yml`** - Couple's names and basic information
- **`events.yml`** - List of events with dates and locations
- **`people.yml`** - Wedding party members
- **`faq.yml`** - Frequently asked questions
- **`navigation.yml`** - Navigation menu links
- **`registries.yml`** - Gift registries

Edit these files to customize your site's content without touching any HTML.

### Working with Includes

Includes are reusable HTML components stored in `src/_includes/`. Common includes:

- **`our_story.html`** - Couple's story section
- **`people.html`** - Wedding party display
- **`events.html`** - Events listing
- **`registry.html`** - Gift registry links
- **`faq.html`** - FAQ section
- **`photo-gallery.html`** - Photo gallery
- **`modals/`** - Modal dialog templates (RSVP, forms, etc.)

To use an include, reference it in your page:

```html
{% include people.html %}
```

Or conditionally:

```html
{% if page.show_story %}
  {% include our_story.html %}
{% endif %}
```

## Theme Customization

### Colors

Edit `src/_data/settings.yml` to change the theme colors:

```yaml
theme:
  text_color: '#2b2b2d'
  primary_color: '#345c8c'
  secondary_color: '#9fb7cc'
```

### Hero Image

Set the homepage hero image in `settings.yml`:

```yaml
hero_image: assets/img/flowers.jpg
hero_position: center center
```

### RSVP Settings

Configure RSVP functionality in `settings.yml`:

```yaml
rsvp:
  use_code: true
  code: 1234
  post_address: https://your-api-endpoint.com/rsvp
  yes_text: "I'll be there"
  no_text: "I can't make it"
```

## Deployment

### Deploying to GitHub Pages

Run the deployment script:

```bash
./scripts/publish.sh
```

This will build the site for production and push it to GitHub Pages.

### Building for Production

```bash
npm run build
```

This creates an optimized build in the `build/` directory ready for deployment.

## License

The theme is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

