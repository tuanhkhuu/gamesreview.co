# Copilot Instructions - GamesReview.com

## Project-Specific Patterns

### Authentication Architecture (CRITICAL)

- **OAuth-only authentication** - NO password authentication (`has_secure_password` is NOT used)
- Users authenticate via Google using `omniauth` and `authentication-zero` gems
- Multiple OAuth providers per user supported via `OauthIdentity` model (currently only Google enabled)
- Session-based auth with signed cookies (2-week validity) - see `ApplicationController#authenticate`
- Request context pattern: `Current.session`, `Current.user`, `Current.user_agent`, `Current.ip_address`
- Example: `app/models/user.rb`, `app/services/oauth_authentication_service.rb`

### Service Object Pattern

- Extract complex business logic into service objects in `app/services/`
- Return `Result` struct with `success`, `user`, `error`, `error_type` attributes
- Example: `OauthAuthenticationService#call` handles user creation, identity linking, email verification
- Use service objects for: OAuth flows, payment processing, complex validations, multi-step operations

### Testing Patterns

- **Minitest** framework with parallel execution
- Custom test helper `sign_in_as(user)` simulates full OAuth callback flow - see `test/test_helper.rb`
- OmniAuth test mode setup with mock auth hashes
- Clean database state per test (all data deleted in `setup` blocks)
- No fixtures - data created explicitly per test
- Run tests: `bin/rails test` or `bin/rails test:all`

### Rails 8 & Modern Stack

- **Solid Queue** for background jobs (not Sidekiq) - configured in `config/queue.yml`
- **Solid Cache** for caching (not Redis) - configured in `config/cache.yml`
- **Solid Cable** for WebSockets (not ActionCable) - configured in `config/cable.yml`
- **Hotwire** (Turbo + Stimulus) for frontend interactivity - controllers in `app/javascript/controllers/`
- **Tailwind CSS** - utility classes in views, custom styles in `app/assets/stylesheets/application.css`
- **Importmap** for JavaScript - no webpack/esbuild - see `config/importmap.rb`

### Documentation & Planning

- Feature specs in `docs/features/` - start with `20251202_game_review_system_master.md` for roadmap
- 7-phase implementation plan: Foundation → Game Discovery → Reviews → Social → Moderation → Analytics → Polish
- Agent-specific instructions in `.github/agents/`: `planning.agent.md`, `code.agent.md`, `review.agent.md`

### Authorization & Security

- **Pundit** for authorization (not CanCanCan) - policies in `app/policies/`
- Email verification required for account linking (see `OauthAuthenticationService#email_verified?`)
- Brakeman for security scanning: `bin/brakeman`
- Bundler Audit for gem vulnerabilities: `bin/bundler-audit`

### Key Files to Reference

- Authentication: `app/controllers/application_controller.rb`, `app/models/user.rb`
- OAuth flow: `app/controllers/omniauth_callbacks_controller.rb`, `app/services/oauth_authentication_service.rb`
- Test helpers: `test/test_helper.rb`
- Routes: `config/routes.rb` (RESTful OAuth pattern)
- Database: `db/schema.rb` (PostgreSQL 14+)

### Development Commands

- Start server: `bin/dev` (Procfile.dev - runs Puma + Tailwind watcher)
- Console: `bin/rails console`
- Migrations: `bin/rails db:migrate`
- Tests: `bin/rails test` or `bin/rails test:all`
- Linting: `bin/rubocop`
- Security scans: `bin/ci` (runs Brakeman + Bundler Audit)
