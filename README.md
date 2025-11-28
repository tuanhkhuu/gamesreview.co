# Games Review

A modern Ruby on Rails application for reviewing and rating video games. Built with Rails 8.0, featuring OAuth-only authentication and a clean, responsive interface.

## Features

- 🎮 Browse and search video games
- ⭐ Rate and review games
- 🔐 Secure OAuth-only authentication (no passwords!)
- 👤 User profiles with connected accounts
- 📱 Responsive design with Tailwind CSS
- ⚡ Modern interactions with Hotwire (Turbo + Stimulus)

## Requirements

- **Ruby**: 3.3.0 or higher
- **Rails**: 8.0.0 or higher
- **Database**: PostgreSQL 14+
- **Node.js**: 18+ (for asset compilation)
- **Redis**: 7+ (for caching and background jobs)

## Authentication

This application uses **OAuth-only authentication** - no passwords required! Users can sign in with:

- 🔵 **Google**
- 🐦 **Twitter**
- 📘 **Facebook**

Users can connect multiple OAuth providers to their account for flexible sign-in options.

### OAuth Setup for Development

To enable authentication in development, you'll need to create OAuth applications with each provider:

#### 1. Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select existing)
3. Navigate to "APIs & Services" → "Credentials"
4. Click "Create Credentials" → "OAuth 2.0 Client ID"
5. Configure OAuth consent screen if prompted
6. Set application type to "Web application"
7. Add authorized redirect URI:
   ```
   http://localhost:3000/auth/google_oauth2/callback
   ```
8. Copy your Client ID and Client Secret

#### 2. Twitter OAuth Setup

1. Go to [Twitter Developer Portal](https://developer.twitter.com/)
2. Create a new app (or use existing)
3. Enable OAuth 2.0 authentication
4. Add callback URL:
   ```
   http://localhost:3000/auth/twitter2/callback
   ```
5. Request email permission (Settings → User authentication settings)
6. Copy your Client ID and Client Secret

#### 3. Facebook OAuth Setup

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app (select "Consumer" type)
3. Add "Facebook Login" product
4. Configure OAuth redirect URIs in Facebook Login Settings:
   ```
   http://localhost:3000/auth/facebook/callback
   ```
5. Copy your App ID and App Secret

### Environment Configuration

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Add your OAuth credentials to `.env`:

   ```bash
   # Google OAuth
   GOOGLE_CLIENT_ID=your_google_client_id
   GOOGLE_CLIENT_SECRET=your_google_client_secret

   # Twitter OAuth
   TWITTER_CLIENT_ID=your_twitter_client_id
   TWITTER_CLIENT_SECRET=your_twitter_client_secret

   # Facebook OAuth
   FACEBOOK_APP_ID=your_facebook_app_id
   FACEBOOK_APP_SECRET=your_facebook_app_secret
   ```

3. **Important**: Never commit your `.env` file to version control!

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/tuanhkhuu/gamesreview.co.git
cd gamesreview.co
```

### 2. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install JavaScript dependencies
npm install
```

### 3. Database Setup

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Load seed data (optional)
rails db:seed
```

### 4. Start the Development Server

```bash
# Start all services (Rails, CSS, JS)
bin/dev

# Or start individually:
rails server           # Rails server on port 3000
npm run build:css -- --watch   # Tailwind CSS compilation
```

Visit [http://localhost:3000](http://localhost:3000) to see the application.

## Testing

### Running Tests

```bash
# Run all tests
rails test

# Run specific test types
rails test:models
rails test:controllers
rails test:system

# Run specific test file
rails test test/models/user_test.rb

# Run with coverage report
COVERAGE=true rails test
```

### Test Configuration

- **Framework**: Minitest (Rails default)
- **Factories**: FactoryBot for test data
- **System Tests**: Capybara + Selenium for browser testing
- **Coverage**: SimpleCov for coverage reporting

## Development Tools

### Code Quality

```bash
# Ruby linting and style checks
bundle exec rubocop

# Auto-fix style issues
bundle exec rubocop -A

# Security vulnerability scanning
bundle exec brakeman

# Dependency security audit
bundle exec bundle-audit check --update
```

### Database Tools

```bash
# Reset database
rails db:reset

# Rollback last migration
rails db:rollback

# Check migration status
rails db:migrate:status

# Open database console
rails dbconsole
```

### Console

```bash
# Rails console
rails console

# Sandbox mode (changes rolled back on exit)
rails console --sandbox
```

## Project Structure

```
app/
├── controllers/        # Request handling
├── models/            # Business logic and data models
├── views/             # HTML templates (ERB)
├── services/          # Complex business logic (Service Objects)
├── javascript/        # Stimulus controllers, JS
├── assets/            # Images, stylesheets
└── helpers/           # View helpers

config/
├── routes.rb          # URL routing
├── database.yml       # Database configuration
├── initializers/      # Framework configuration
└── environments/      # Environment-specific settings

db/
├── migrate/           # Database migrations
└── schema.rb          # Current database schema

docs/
├── features/          # Feature documentation
├── api/              # API documentation
└── architecture/      # Architecture decisions (ADRs)

test/
├── models/           # Model tests
├── controllers/      # Controller tests
├── system/           # End-to-end tests
└── factories/        # FactoryBot factories
```

## Deployment

### Production Requirements

- PostgreSQL database
- Redis server
- HTTPS enabled (required for OAuth callbacks)
- Environment variables configured

### Environment Variables (Production)

Set these in your production environment:

```bash
# OAuth Credentials (use production callback URLs)
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
TWITTER_CLIENT_ID=...
TWITTER_CLIENT_SECRET=...
FACEBOOK_APP_ID=...
FACEBOOK_APP_SECRET=...

# Application
SECRET_KEY_BASE=... (generate with: rails secret)
RAILS_ENV=production
APP_HOST=yourdomain.com
APP_PROTOCOL=https

# Database
DATABASE_URL=postgresql://...

# Redis (for caching/sessions/jobs)
REDIS_URL=redis://...
```

### OAuth Callback URLs (Production)

Update your OAuth apps with production callback URLs:

```
Google:   https://yourdomain.com/auth/google_oauth2/callback
Twitter:  https://yourdomain.com/auth/twitter2/callback
Facebook: https://yourdomain.com/auth/facebook/callback
```

### Deploy Commands

```bash
# Precompile assets
rails assets:precompile

# Run migrations
rails db:migrate

# Start server (using Puma)
bundle exec puma -C config/puma.rb
```

## Managing Connected Accounts

Users can manage their OAuth provider connections:

1. Sign in with any connected provider
2. Navigate to Settings → Connected Accounts
3. **Connect additional providers**: Click "Connect [Provider]" button
4. **Disconnect providers**: Click "Disconnect" (must keep at least one)

**Note**: Users must always have at least one connected OAuth provider to maintain access to their account.

## Troubleshooting

### Common Issues

#### "Redirect URI mismatch" when signing in

**Cause**: OAuth callback URL doesn't match provider configuration

**Solution**:

- Verify exact callback URL in provider console matches your application
- Check for `http` vs `https`
- Ensure port number matches (`:3000` for localhost)

#### "Cannot connect to database"

**Solution**:

```bash
# Check PostgreSQL is running
brew services list  # macOS
sudo systemctl status postgresql  # Linux

# Verify database exists
rails db:create
```

#### OAuth credentials not working

**Solution**:

- Check `.env` file exists and has correct values
- Verify no trailing spaces in credentials
- Restart Rails server after changing `.env`
- Ensure OAuth app is enabled in provider console

#### Tests failing

**Solution**:

```bash
# Ensure test database is set up
RAILS_ENV=test rails db:create db:migrate

# Clear test cache
rails tmp:clear

# Run specific failing test for details
rails test test/path/to/failing_test.rb -v
```

## Documentation

- **Features**: [`docs/features/`](docs/features/) - Feature documentation
- **API**: [`docs/api/`](docs/api/) - API endpoint documentation
- **Architecture**: [`docs/architecture/`](docs/architecture/) - Technical decisions

Key documentation files:

- [OAuth Authentication](docs/features/20251127_oauth_authentication.md)
- [OAuth API Endpoints](docs/api/20251127_oauth_endpoints.md)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Ruby style guide (enforced by Rubocop)
- Write tests for new features
- Update documentation for significant changes
- Keep commits focused and atomic
- Write descriptive commit messages

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/tuanhkhuu/gamesreview.co/issues)
- **Documentation**: [`docs/`](docs/)
- **Email**: support@gamesreview.com (if configured)

## Acknowledgments

- Built with [Ruby on Rails](https://rubyonrails.org/)
- Authentication via [OmniAuth](https://github.com/omniauth/omniauth)
- Styled with [Tailwind CSS](https://tailwindcss.com/)
- Interactive features with [Hotwire](https://hotwired.dev/)
