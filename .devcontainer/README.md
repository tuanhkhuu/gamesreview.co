# Ruby on Rails 8 DevContainer

This devcontainer provides a complete development environment for Ruby on Rails 8 applications.

## What's Included

- **Ruby 3.3** - Latest stable Ruby version
- **Rails 8** - Installed via postCreateCommand
- **PostgreSQL 16** - Database server
- **Node.js LTS** - For JavaScript/asset compilation
- **Git** - Version control

## VS Code Extensions

- Ruby LSP (Shopify) - Language server for Ruby
- Ruby Debug (rdbg) - Debugging support
- Tailwind CSS - CSS framework support
- Prettier - Code formatting

## Getting Started

1. Open this folder in VS Code
2. Click "Reopen in Container" when prompted (or use Command Palette: "Dev Containers: Reopen in Container")
3. Wait for the container to build and start
4. Create a new Rails app or work with an existing one:

```bash
# Create a new Rails 8 app (skipping test framework to use RSpec)
rails new . --database=postgresql --css=tailwind --skip-test

# Or if you already have a Rails app:
bundle install
rails db:create db:migrate
```

## Running the Application

```bash
# Start the Rails server
rails server

# The app will be available at http://localhost:3000
```

## Database Configuration

The PostgreSQL database is pre-configured with:

- Host: localhost
- User: postgres
- Password: postgres
- Database: gamesreview_development

The `DATABASE_URL` environment variable is already set in the container.
