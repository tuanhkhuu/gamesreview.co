# Feature: Media Management (Screenshots & Videos)

**Phase:** 2 (Weeks 5-8)  
**Dependencies:** Phase 1 (Game, Screenshot, Video models)  
**Status:** Ready for Implementation

---

## User Stories

- **US-5:** I want to see gameplay videos and screenshots so I can preview the game

---

## Functional Requirements

### FR-5: Media Management

**FR-5.1: Screenshots**

- System shall display game screenshots in a gallery
- System shall support multiple screenshots per game
- System shall allow platform-specific screenshots
- System shall support featured/highlighted screenshots
- System shall provide lightbox/modal view for full-size images
- System shall maintain display order for screenshots

**FR-5.2: Videos**

- System shall embed game trailers from YouTube/Vimeo
- System shall support multiple videos per game (trailers, gameplay, reviews)
- System shall categorize videos by type
- System shall display video thumbnails and durations
- System shall show most recent trailer prominently

---

## Screenshot Management

### Database Schema

```ruby
class Screenshot < ApplicationRecord
  belongs_to :game
  belongs_to :platform, optional: true

  has_one_attached :image

  enum category: {
    gameplay: 'gameplay',
    cutscene: 'cutscene',
    menu: 'menu',
    cover: 'cover'
  }

  validates :image, presence: true
  validates :display_order, presence: true, numericality: { only_integer: true }
  validate :image_format_and_size

  scope :ordered, -> { order(:display_order) }
  scope :featured, -> { where(featured: true) }

  private

  def image_format_and_size
    return unless image.attached?

    unless image.content_type.in?(%w[image/jpeg image/jpg image/png image/webp])
      errors.add(:image, 'must be JPEG, PNG, or WebP')
    end

    if image.byte_size > 10.megabytes
      errors.add(:image, 'must be less than 10MB')
    end
  end
end
```

### UI Specifications

**Gallery Display (Game Detail Page):**

**Layout:**

- Horizontal scrollable gallery
- Show 4-5 screenshots at a time on desktop
- Swipe on mobile
- Arrow navigation buttons (left/right)

**Screenshot Card:**

- Thumbnail size: 300x169px (16:9 aspect ratio)
- Click to open lightbox
- Platform badge overlay (bottom-right) if platform-specific
- Featured badge (top-left) for highlighted screenshots

**Lightbox/Modal:**

- Full-screen overlay
- Display full-resolution image (max 1920x1080)
- Previous/Next navigation arrows
- Close button (X)
- Image counter (e.g., "3 / 12")
- Keyboard navigation: Arrow keys, ESC to close
- Click outside image to close

**Admin Interface (Screenshot Upload):**

- Drag & drop upload area
- Multiple file selection
- Image preview before save
- Set display order (drag to reorder)
- Mark as featured checkbox
- Select platform (optional)
- Select category (dropdown)
- Delete button per screenshot

---

## Video Management

### Database Schema

```ruby
class Video < ApplicationRecord
  belongs_to :game

  enum video_type: {
    trailer: 'trailer',
    gameplay: 'gameplay',
    review: 'review',
    interview: 'interview'
  }

  enum provider: {
    youtube: 'youtube',
    vimeo: 'vimeo'
  }

  validates :url, presence: true, format: { with: URI::regexp(%w[http https]) }
  validates :video_id, presence: true
  validates :provider, presence: true
  validates :video_type, presence: true
  validate :whitelisted_domain

  scope :ordered, -> { order(published_at: :desc) }
  scope :trailers, -> { where(video_type: 'trailer') }

  before_validation :extract_video_id

  private

  def whitelisted_domain
    allowed_domains = ['youtube.com', 'youtu.be', 'vimeo.com']
    uri = URI.parse(url)
    unless allowed_domains.any? { |domain| uri.host&.include?(domain) }
      errors.add(:url, 'must be from YouTube or Vimeo')
    end
  rescue URI::InvalidURIError
    errors.add(:url, 'is not a valid URL')
  end

  def extract_video_id
    return if url.blank?

    uri = URI.parse(url)

    if uri.host&.include?('youtube.com')
      self.provider = 'youtube'
      self.video_id = CGI.parse(uri.query || '')['v']&.first
    elsif uri.host&.include?('youtu.be')
      self.provider = 'youtube'
      self.video_id = uri.path[1..-1]
    elsif uri.host&.include?('vimeo.com')
      self.provider = 'vimeo'
      self.video_id = uri.path[1..-1]
    end
  rescue URI::InvalidURIError
    nil
  end
end
```

### UI Specifications

**Video Display (Game Detail Page):**

**Featured Trailer:**

- Large embed (16:9 aspect ratio)
- 640x360px on desktop
- Full width on mobile
- Show most recent trailer by default
- Play button overlay

**Additional Videos:**

- Horizontal scrollable list below featured video
- Video thumbnails (200x113px)
- Video type badge (top-left): "Trailer", "Gameplay", "Review"
- Duration overlay (bottom-right)
- Click to replace featured video

**Video Embed:**

- YouTube iframe embed
- Vimeo iframe embed
- Lazy loading (load on scroll or click)
- Responsive sizing

**Embed Code Examples:**

```html
<!-- YouTube -->
<iframe
  width="640"
  height="360"
  src="https://www.youtube.com/embed/<%= video.video_id %>"
  frameborder="0"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen
  loading="lazy"
>
</iframe>

<!-- Vimeo -->
<iframe
  src="https://player.vimeo.com/video/<%= video.video_id %>"
  width="640"
  height="360"
  frameborder="0"
  allow="autoplay; fullscreen; picture-in-picture"
  allowfullscreen
  loading="lazy"
>
</iframe>
```

**Admin Interface (Video Management):**

- Add video URL input field
- Auto-detect provider (YouTube/Vimeo)
- Extract video ID automatically
- Select video type (dropdown)
- Set published date
- Preview embed before save
- Delete button per video

---

## Storage & CDN

**Screenshot Storage:**

- ActiveStorage with S3 backend
- Image variants for responsive images:
  - Thumbnail: 300x169px
  - Medium: 800x450px
  - Large: 1920x1080px
- WebP format for modern browsers with JPEG fallback

**CDN Configuration:**

- CloudFront or CloudFlare
- Cache screenshots for 30 days
- Invalidate on delete/update

**Example ActiveStorage Variant:**

```ruby
class Screenshot < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [300, 169]
    attachable.variant :medium, resize_to_limit: [800, 450]
    attachable.variant :large, resize_to_limit: [1920, 1080]
  end
end
```

---

## Security Requirements

- **NFR-30:** Image uploads shall be validated for file type, size (< 10MB), and content
- **NFR-31:** Video embeds shall only allow whitelisted domains (YouTube, Vimeo)

**Image Validation:**

- File type: JPEG, PNG, WebP only
- Max size: 10MB
- Scan for malicious content (ActiveStorage virus scanning)

**Video Validation:**

- Only YouTube and Vimeo URLs allowed
- Validate URL format before saving
- Sanitize embed code to prevent XSS

---

## Performance Requirements

**Screenshots:**

- Lazy load images (load on scroll)
- Use responsive images (srcset)
- Compress images before upload (ImageMagick/libvips)
- Serve WebP where supported

**Videos:**

- Lazy load iframes (load on click or scroll)
- Thumbnail images from YouTube/Vimeo APIs
- No autoplay (user-initiated only)

---

## Testing Checklist

- [ ] Upload screenshots (JPEG, PNG, WebP)
- [ ] Reject invalid file types
- [ ] Reject files > 10MB
- [ ] Screenshot gallery displays correctly
- [ ] Lightbox opens on click
- [ ] Lightbox navigation works (arrows, keyboard)
- [ ] Reorder screenshots (admin)
- [ ] Mark screenshot as featured
- [ ] Add YouTube video (URL auto-detected)
- [ ] Add Vimeo video (URL auto-detected)
- [ ] Reject non-whitelisted video URLs
- [ ] Video embeds display correctly
- [ ] Video type badges display
- [ ] Lazy loading works
- [ ] Responsive on mobile

---

## Data Sources

**Screenshots:**

- IGDB API (provides official screenshots)
- Steam API (community screenshots)
- Manual admin upload

**Videos:**

- YouTube (official game channels)
- Manual admin curation

---

**Next Phase:** Phase 3 - Critic Review System
