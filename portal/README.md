# Infrastructure Portal

Self-service portal for GCP infrastructure provisioning with approval workflow.

## Features

- **Request Management**: Create and track infrastructure requests
- **Approval Workflow**: Multi-level approval for production environments
- **Dynamic Forms**: JSON Schema-based configuration forms
- **Google OAuth**: Secure authentication with Google
- **Role-based Access**: User, Approver, and Admin roles

## Tech Stack

- **Backend**: Go + Fiber + GORM
- **Frontend**: Next.js 14 + Tailwind + shadcn/ui
- **Database**: PostgreSQL
- **Auth**: Google OAuth + JWT

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Google OAuth credentials (for authentication)

### Setup

1. Copy environment file:
   ```bash
   cp .env.example .env
   ```

2. Configure Google OAuth:
   - Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Create OAuth 2.0 Client ID
   - Add `http://localhost:10800/api/auth/google/callback` to authorized redirect URIs
   - Update `.env` with your credentials

3. Start services:
   ```bash
   docker-compose up -d
   ```

4. Access the portal:
   - Frontend: http://localhost:10300
   - Backend API: http://localhost:10800

## Development

### Backend

```bash
cd backend
go mod download
go run ./cmd/server
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## API Endpoints

### Auth
- `GET /api/auth/google` - Initiate Google OAuth
- `GET /api/auth/google/callback` - OAuth callback
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout

### Requests
- `GET /api/requests` - List requests
- `POST /api/requests` - Create request
- `GET /api/requests/:id` - Get request
- `PUT /api/requests/:id` - Update request
- `DELETE /api/requests/:id` - Delete request
- `POST /api/requests/:id/submit` - Submit for approval

### Approvals
- `GET /api/approvals` - List pending approvals
- `POST /api/approvals/:id/approve` - Approve request
- `POST /api/approvals/:id/reject` - Reject request

### Resources
- `GET /api/environments` - List environments
- `GET /api/resource-types` - List resource types
- `GET /api/resource-types/:id/schema` - Get config schema

## Project Structure

```
portal/
├── backend/
│   ├── cmd/server/         # Entry point
│   ├── internal/
│   │   ├── config/         # Configuration
│   │   ├── handlers/       # HTTP handlers
│   │   ├── middleware/     # Auth middleware
│   │   ├── models/         # Domain models
│   │   └── repository/     # Database layer
│   ├── go.mod
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── app/            # Next.js pages
│   │   ├── components/     # React components
│   │   └── lib/            # API client, auth
│   ├── package.json
│   └── Dockerfile
└── docker-compose.yml
```

## License

MIT
