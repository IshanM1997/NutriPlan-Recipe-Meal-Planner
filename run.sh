#!/usr/bin/env bash
# =============================================================================
#  NutriPlan — Full Project Setup & Run Script
#  Works on macOS and Linux
#  Usage:
#    chmod +x run.sh
#    ./run.sh setup      → install everything + seed DB (first time)
#    ./run.sh start      → start backend + frontend together
#    ./run.sh backend    → start Django only
#    ./run.sh frontend   → start Angular only
#    ./run.sh seed       → re-seed the database
#    ./run.sh reset      → wipe DB and re-seed
#    ./run.sh stop       → kill both servers
#    ./run.sh status     → show running servers
# =============================================================================

set -e

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
VENV_DIR="$BACKEND_DIR/venv"
PID_DIR="$SCRIPT_DIR/.pids"

mkdir -p "$PID_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
header()  { echo -e "\n${BOLD}${BLUE}━━━  $*  ━━━${NC}\n"; }

# ── Prerequisite checks ───────────────────────────────────────────────────────
check_prerequisites() {
  header "Checking prerequisites"

  command -v python3 >/dev/null 2>&1 || error "python3 not found. Install Python 3.10+"
  PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
  info "Python $PY_VERSION found"

  command -v pip3 >/dev/null 2>&1 || error "pip3 not found"
  info "pip3 found"

  command -v node >/dev/null 2>&1 || error "Node.js not found. Install Node 18+"
  NODE_VERSION=$(node --version)
  info "Node $NODE_VERSION found"

  command -v npm >/dev/null 2>&1 || error "npm not found"
  NPM_VERSION=$(npm --version)
  info "npm $NPM_VERSION found"

  success "All prerequisites met"
}

# ── Backend setup ─────────────────────────────────────────────────────────────
setup_backend() {
  header "Setting up Django backend"

  cd "$BACKEND_DIR"

  # Virtual environment
  if [ ! -d "$VENV_DIR" ]; then
    info "Creating Python virtual environment…"
    python3 -m venv "$VENV_DIR"
    success "Virtual environment created at $VENV_DIR"
  else
    info "Virtual environment already exists — skipping creation"
  fi

  # Activate venv
  source "$VENV_DIR/bin/activate"

  # Install dependencies
  info "Installing Python dependencies…"
  pip install --upgrade pip --quiet
  pip install -r requirements.txt --quiet
  success "Python dependencies installed"

  # Copy .env if missing
  if [ ! -f "$BACKEND_DIR/.env" ]; then
    if [ -f "$BACKEND_DIR/.env.example" ]; then
      cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
      info ".env file created from .env.example"
    fi
  fi

  # Run migrations
  info "Running database migrations…"
  python manage.py migrate --run-syncdb 2>&1 | grep -v "^$" | sed 's/^/  /'
  success "Migrations complete"

  # Seed data
  seed_database

  deactivate
}

# ── Seed database ─────────────────────────────────────────────────────────────
seed_database() {
  header "Seeding database"
  cd "$BACKEND_DIR"
  source "$VENV_DIR/bin/activate"
  python manage.py seed_data
  success "Database seeded"
  echo ""
  echo -e "  ${BOLD}Demo credentials:${NC}"
  echo -e "  Email:    ${CYAN}demo@nutriplan.com${NC}"
  echo -e "  Password: ${CYAN}demo1234${NC}"
  echo ""
  deactivate
}

# ── Frontend setup ────────────────────────────────────────────────────────────
setup_frontend() {
  header "Setting up Angular frontend"

  cd "$FRONTEND_DIR"

  if [ ! -d "node_modules" ]; then
    info "Installing npm dependencies (this may take a minute)…"
    npm install --legacy-peer-deps 2>&1 | tail -5
    success "npm dependencies installed"
  else
    info "node_modules already exists — skipping install"
    info "Run 'npm install' in frontend/ manually if you need to update"
  fi
}

# ── Start backend ─────────────────────────────────────────────────────────────
start_backend() {
  info "Starting Django development server on http://localhost:8000 …"

  cd "$BACKEND_DIR"
  source "$VENV_DIR/bin/activate"

  python manage.py runserver 8000 > "$PID_DIR/backend.log" 2>&1 &
  BACKEND_PID=$!
  echo "$BACKEND_PID" > "$PID_DIR/backend.pid"

  deactivate

  # Wait and verify
  sleep 2
  if kill -0 "$BACKEND_PID" 2>/dev/null; then
    success "Django server running (PID $BACKEND_PID)"
    info "API root:  http://localhost:8000/api/"
    info "Admin:     http://localhost:8000/admin/"
    info "Log:       $PID_DIR/backend.log"
  else
    error "Django server failed to start. Check $PID_DIR/backend.log"
  fi
}

# ── Start frontend ────────────────────────────────────────────────────────────
start_frontend() {
  info "Starting Angular dev server on http://localhost:4200 …"

  cd "$FRONTEND_DIR"

  npx ng serve --proxy-config proxy.conf.json --port 4200 \
    > "$PID_DIR/frontend.log" 2>&1 &
  FRONTEND_PID=$!
  echo "$FRONTEND_PID" > "$PID_DIR/frontend.pid"

  # Wait for Angular compilation
  info "Waiting for Angular to compile (up to 60s)…"
  for i in $(seq 1 30); do
    sleep 2
    if grep -q "Application bundle generation complete" "$PID_DIR/frontend.log" 2>/dev/null || \
       grep -q "Compiled successfully" "$PID_DIR/frontend.log" 2>/dev/null || \
       grep -q "Local:   http://localhost:4200" "$PID_DIR/frontend.log" 2>/dev/null; then
      success "Angular dev server ready"
      break
    fi
    if ! kill -0 "$FRONTEND_PID" 2>/dev/null; then
      error "Angular server crashed. Check $PID_DIR/frontend.log"
    fi
    echo -n "."
  done
  echo ""
  info "App URL: http://localhost:4200"
  info "Log:     $PID_DIR/frontend.log"
}

# ── Stop servers ──────────────────────────────────────────────────────────────
stop_servers() {
  header "Stopping servers"

  for name in backend frontend; do
    PID_FILE="$PID_DIR/$name.pid"
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        success "$name server (PID $PID) stopped"
      else
        warn "$name PID file exists but process not running"
      fi
      rm -f "$PID_FILE"
    else
      warn "No PID file for $name"
    fi
  done

  # Also kill any lingering ng / manage.py processes
  pkill -f "manage.py runserver" 2>/dev/null && info "Killed stray Django process" || true
  pkill -f "ng serve"            2>/dev/null && info "Killed stray ng process"     || true

  success "All servers stopped"
}

# ── Status ────────────────────────────────────────────────────────────────────
show_status() {
  header "Server status"

  for name in backend frontend; do
    PID_FILE="$PID_DIR/$name.pid"
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      if kill -0 "$PID" 2>/dev/null; then
        echo -e "  ${GREEN}●${NC} $name running (PID $PID)"
      else
        echo -e "  ${RED}●${NC} $name PID file exists but process is dead"
      fi
    else
      echo -e "  ${RED}●${NC} $name not running"
    fi
  done
}

# ── Reset database ────────────────────────────────────────────────────────────
reset_database() {
  header "Resetting database"
  warn "This will delete all data and re-seed from scratch."
  read -r -p "Continue? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    cd "$BACKEND_DIR"
    source "$VENV_DIR/bin/activate"
    rm -f db.sqlite3
    success "Database deleted"
    python manage.py migrate --run-syncdb 2>&1 | grep -v "^$" | sed 's/^/  /'
    success "Migrations re-applied"
    deactivate
    seed_database
  else
    info "Reset cancelled"
  fi
}

# ── Print summary banner ──────────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║          🥗  NutriPlan is running!                  ║${NC}"
  echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
  echo -e "${BOLD}${GREEN}║${NC}  App (Angular)  →  ${CYAN}http://localhost:4200${NC}           ${BOLD}${GREEN}║${NC}"
  echo -e "${BOLD}${GREEN}║${NC}  API (Django)   →  ${CYAN}http://localhost:8000/api/${NC}      ${BOLD}${GREEN}║${NC}"
  echo -e "${BOLD}${GREEN}║${NC}  Admin panel    →  ${CYAN}http://localhost:8000/admin/${NC}    ${BOLD}${GREEN}║${NC}"
  echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
  echo -e "${BOLD}${GREEN}║${NC}  Demo login: ${YELLOW}demo@nutriplan.com${NC} / ${YELLOW}demo1234${NC}      ${BOLD}${GREEN}║${NC}"
  echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
  echo -e "${BOLD}${GREEN}║${NC}  Press ${RED}Ctrl+C${NC} or run ${YELLOW}./run.sh stop${NC} to quit       ${BOLD}${GREEN}║${NC}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── Trap Ctrl+C ───────────────────────────────────────────────────────────────
cleanup() {
  echo ""
  warn "Interrupted — stopping servers…"
  stop_servers
  exit 0
}
trap cleanup INT TERM

# ── Main dispatcher ───────────────────────────────────────────────────────────
COMMAND="${1:-help}"

case "$COMMAND" in

  setup)
    check_prerequisites
    setup_backend
    setup_frontend
    echo ""
    success "Setup complete! Run './run.sh start' to launch the app."
    ;;

  start)
    check_prerequisites
    # Auto-setup if venv or node_modules missing
    [ ! -d "$VENV_DIR" ]          && setup_backend  || true
    [ ! -d "$FRONTEND_DIR/node_modules" ] && setup_frontend || true
    header "Starting NutriPlan"
    start_backend
    start_frontend
    print_summary
    # Keep script alive so Ctrl+C works
    wait
    ;;

  backend)
    [ ! -d "$VENV_DIR" ] && setup_backend || true
    header "Starting Django backend only"
    start_backend
    info "Tail logs: tail -f $PID_DIR/backend.log"
    wait
    ;;

  frontend)
    [ ! -d "$FRONTEND_DIR/node_modules" ] && setup_frontend || true
    header "Starting Angular frontend only"
    start_frontend
    info "Tail logs: tail -f $PID_DIR/frontend.log"
    wait
    ;;

  seed)
    [ ! -d "$VENV_DIR" ] && error "Run './run.sh setup' first"
    seed_database
    ;;

  reset)
    [ ! -d "$VENV_DIR" ] && error "Run './run.sh setup' first"
    reset_database
    ;;

  stop)
    stop_servers
    ;;

  status)
    show_status
    ;;

  logs)
    TARGET="${2:-both}"
    case "$TARGET" in
      backend)  tail -f "$PID_DIR/backend.log" ;;
      frontend) tail -f "$PID_DIR/frontend.log" ;;
      *)
        echo "=== BACKEND ===" && tail -20 "$PID_DIR/backend.log" 2>/dev/null || warn "No backend log"
        echo "" && echo "=== FRONTEND ===" && tail -20 "$PID_DIR/frontend.log" 2>/dev/null || warn "No frontend log"
        ;;
    esac
    ;;

  help|*)
    echo ""
    echo -e "${BOLD}NutriPlan — Run Script${NC}"
    echo ""
    echo -e "  ${CYAN}./run.sh setup${NC}          Install deps, migrate DB, seed data"
    echo -e "  ${CYAN}./run.sh start${NC}          Start backend + frontend (auto-setup if needed)"
    echo -e "  ${CYAN}./run.sh backend${NC}        Start Django server only (port 8000)"
    echo -e "  ${CYAN}./run.sh frontend${NC}       Start Angular server only (port 4200)"
    echo -e "  ${CYAN}./run.sh seed${NC}           Re-seed the database"
    echo -e "  ${CYAN}./run.sh reset${NC}          Wipe database and re-seed"
    echo -e "  ${CYAN}./run.sh stop${NC}           Stop all servers"
    echo -e "  ${CYAN}./run.sh status${NC}         Show running server status"
    echo -e "  ${CYAN}./run.sh logs [backend|frontend]${NC}   Tail server logs"
    echo ""
    echo -e "  ${BOLD}First time?${NC} Run: ${YELLOW}./run.sh setup && ./run.sh start${NC}"
    echo ""
    ;;
esac
