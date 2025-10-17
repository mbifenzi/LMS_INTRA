#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project name
PROJECT_NAME="LMS_INTRA"

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Help menu
show_help() {
    print_header "LMS Docker Management Script"
    echo ""
    echo "Usage: ./docker.sh [command]"
    echo ""
    echo "Setup Commands:"
    echo "  init              - Initialize project (build, migrate, create superuser)"
    echo "  build             - Build all Docker containers"
    echo "  up                - Start all containers"
    echo "  down              - Stop all containers"
    echo "  restart           - Restart all containers"
    echo "  clean             - Stop containers and remove volumes (WARNING: deletes data)"
    echo ""
    echo "Database Commands:"
    echo "  migrate           - Run Django migrations"
    echo "  makemigrations    - Create new migrations"
    echo "  createsuperuser   - Create Django superuser"
    echo "  seed-all          - Create superuser + seed all demo data"
    echo "  db-summary        - Show database statistics and courses"
    echo "  dbshell           - Open database shell"
    echo "  resetdb           - Reset database (WARNING: deletes all data)"
    echo ""
    echo "Backend Commands:"
    echo "  shell             - Open Django shell"
    echo "  bash              - Open bash in backend container"
    echo "  logs              - Show backend logs"
    echo "  test              - Run backend tests"
    echo ""
    echo "Global Auth Commands:"
    echo "  auth-logs         - Show GLOBAL-AUTH logs"
    echo "  auth-bash         - Open bash in GLOBAL-AUTH container"
    echo "  create-user       - Create a test user in GLOBAL-AUTH"
    echo ""
    echo "Frontend Commands:"
    echo "  front-logs        - Show frontend logs"
    echo "  front-bash        - Open bash in frontend container"
    echo ""
    echo "Utility Commands:"
    echo "  ps                - Show running containers"
    echo "  status            - Show detailed status of all services"
    echo "  logs-all          - Show logs from all containers"
    echo "  help              - Show this help message"
    echo ""
}

# Initialize project
init_project() {
    print_header "Initializing LMS Project"
    
    print_info "Building containers..."
    docker-compose build
    
    print_info "Starting containers..."
    docker-compose up -d
    
    print_info "Waiting for services to be ready..."
    sleep 10
    
    print_info "Running migrations..."
    docker exec -it astra-learn-back python manage.py migrate
    
    print_info "Creating superuser..."
    docker exec -it astra-learn-back python manage.py createsuperuser
    
    print_info "Setting up frontend (LMS_FRONT)..."
    FRONTEND_DIR="LMS_FRONT"
    (
        cd "$FRONTEND_DIR" || exit 1
        print_info "Running npm install (with legacy peer deps)..."
        npm install --legacy-peer-deps
        print_success "npm install completed."
        print_info "Creating .env file for frontend..."
        cat > .env <<EOF
AUTH_API_URL=http://fastapi-app:80
NEXT_PUBLIC_AUTH_API_URL=http://localhost:8001
EOF
        print_success ".env file created in $FRONTEND_DIR/.env."
    )
    
    print_success "Project initialized successfully!"
    print_info "Access the services at:"
    echo "  - Frontend: http://localhost:3000"
    echo "  - Backend API: http://localhost:8000"
    echo "  - GLOBAL-AUTH: http://localhost:8001"
}

# Build containers
build_containers() {
    print_header "Building Docker Containers"
    docker-compose build
    print_success "Build completed"
}

# Start containers
start_containers() {
    print_header "Starting Containers"
    docker-compose up -d
    print_success "Containers started"
    sleep 5
    docker-compose ps
}

# Stop containers
stop_containers() {
    print_header "Stopping Containers"
    docker-compose down
    print_success "Containers stopped"
}

# Restart containers
restart_containers() {
    print_header "Restarting Containers"
    docker-compose restart
    print_success "Containers restarted"
}

# Clean everything
clean_all() {
    print_warning "This will remove all containers and volumes (all data will be lost)"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        print_header "Cleaning Project"
        docker-compose down -v
        print_success "Cleanup completed"
    else
        print_info "Cleanup cancelled"
    fi
}

# Run migrations
run_migrations() {
    print_header "Running Migrations"
    docker exec -it astra-learn-back python manage.py migrate
    print_success "Migrations completed"
}

# Make migrations
make_migrations() {
    print_header "Creating Migrations"
    docker exec -it astra-learn-back python manage.py makemigrations
    print_success "Migrations created"
}

# Create superuser
create_superuser() {
    print_header "Creating Superuser"
    docker exec -it astra-learn-back python manage.py createsuperuser
}

# Seed all data
seed_all() {
    print_header "Seeding Database"
    
    print_info "Creating superuser (admin@um6p.ma)..."
    docker exec -i astra-learn-back python manage.py shell << 'EOF'
from django.contrib.auth import get_user_model
User = get_user_model()

if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(
        username='admin',
        email='admin@um6p.ma',
        password='Password123',
        first_name='Admin',
        last_name='User'
    )
    print('✓ Superuser created: admin@um6p.ma / Password123')
else:
    print('✓ Superuser already exists')
EOF
    
    print_info "Creating user in GLOBAL-AUTH..."
    docker exec -i fastapi-app curl -s -X POST http://localhost/users/ \
        -H "Content-Type: application/json" \
        -d '{
            "email": "admin@um6p.ma",
            "username": "admin",
            "first_name": "Admin",
            "last_name": "User",
            "password": "Password123",
            "role": "SuperUser"
        }' > /tmp/globalauth_response.json 2>&1
    
    if grep -q '"id"' /tmp/globalauth_response.json 2>/dev/null; then
        print_success "GLOBAL-AUTH user created: admin@um6p.ma / Password123"
    elif grep -q -i "already" /tmp/globalauth_response.json 2>/dev/null; then
        print_success "GLOBAL-AUTH user already exists"
    else
        print_warning "Could not verify GLOBAL-AUTH user creation"
    fi
    rm -f /tmp/globalauth_response.json
    
    print_info "Checking for seed commands..."
    if docker exec astra-learn-back python manage.py help 2>&1 | grep -q "seed_demo_data"; then
        print_info "Running seed_demo_data..."
        docker exec astra-learn-back python manage.py seed_demo_data
        print_success "Demo data seeded"
    elif docker exec astra-learn-back python manage.py help 2>&1 | grep -q "seed_demo"; then
        print_info "Running seed_demo..."
        docker exec astra-learn-back python manage.py seed_demo
        print_success "Demo data seeded"
    else
        print_warning "No seed_demo_data command found, skipping"
    fi
    
    if docker exec astra-learn-back python manage.py help 2>&1 | grep -q "seed_micro"; then
        print_info "Running seed_micro (ECON101 course)..."
        docker exec astra-learn-back python manage.py seed_micro
        print_success "Microeconomics course seeded"
    fi
    
    print_success "Database seeding completed!"
    echo ""
    print_info "Login credentials:"
    echo "  Email:    admin@um6p.ma"
    echo "  Password: Password123"
    echo ""
    print_info "You can now:"
    echo "  - Login to GLOBAL-AUTH: http://localhost:8001/auth/login"
    echo "  - Access Django Admin: http://localhost:8000/admin"
    echo "  - Use the frontend: http://localhost:3000"
}

# Database shell
db_shell() {
    print_header "Opening Database Shell"
    docker exec -it astra-learn-db psql -U lms -d lms
}

# Show database summary
db_summary() {
    print_header "Database Summary"
    docker exec -i astra-learn-back python manage.py shell << 'EOF'
from courses.models import Course, Week, Lesson
from accounts.models import User
from assessments.models import Assignment, Submission
from grades.models import Grade
from quiz_integration.models import QuizLink
from timetable.models import Event

print("\n📊 DATABASE STATISTICS")
print("-" * 60)
print(f"👥 Users:        {User.objects.count()}")
print(f"📚 Courses:      {Course.objects.count()}")
print(f"📅 Weeks:        {Week.objects.count()}")
print(f"📝 Lessons:      {Lesson.objects.count()}")
print(f"📋 Assignments:  {Assignment.objects.count()}")
print(f"📤 Submissions:  {Submission.objects.count()}")
print(f"🎯 Grades:       {Grade.objects.count()}")
print(f"🧪 Quiz Links:   {QuizLink.objects.count()}")
print(f"📆 Events:       {Event.objects.count()}")

print("\n📚 COURSES")
print("-" * 60)
for course in Course.objects.all():
    weeks = course.weeks.count()
    lessons = Lesson.objects.filter(week__course=course).count()
    enrollments = course.enrollments.count()
    print(f"{course.code}: {course.title}")
    print(f"  → {weeks} weeks, {lessons} lessons, {enrollments} enrollments")
print()
EOF
}

# Reset database
reset_db() {
    print_warning "This will delete all data in the database"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        print_header "Resetting Database"
        docker-compose down
        docker volume rm lms_intra_astra_learn_backend_postgres_data
        docker-compose up -d
        sleep 10
        docker exec -it astra-learn-back python manage.py migrate
        print_success "Database reset completed"
        print_info "Don't forget to create a new superuser!"
    else
        print_info "Database reset cancelled"
    fi
}

# Django shell
django_shell() {
    print_header "Opening Django Shell"
    docker exec -it astra-learn-back python manage.py shell
}

# Backend bash
backend_bash() {
    print_header "Opening Backend Bash"
    docker exec -it astra-learn-back bash
}

# Backend logs
backend_logs() {
    print_header "Backend Logs (Ctrl+C to exit)"
    docker-compose logs -f astra-learn-back
}

# Run tests
run_tests() {
    print_header "Running Backend Tests"
    docker exec -it astra-learn-back pytest
}

# GLOBAL-AUTH logs
auth_logs() {
    print_header "GLOBAL-AUTH Logs (Ctrl+C to exit)"
    docker-compose logs -f fastapi-app
}

# GLOBAL-AUTH bash
auth_bash() {
    print_header "Opening GLOBAL-AUTH Bash"
    docker exec -it fastapi-app bash
}

# Create test user in GLOBAL-AUTH
create_test_user() {
    print_header "Creating Test User in GLOBAL-AUTH"
    echo ""
    read -p "Email: " email
    read -p "Username: " username
    read -p "First Name: " firstname
    read -p "Last Name: " lastname
    read -sp "Password: " password
    echo ""
    read -p "Role (Student/Staff/Professor/Admin/SuperUser) [Student]: " role
    role=${role:-Student}
    
    docker exec -it fastapi-app curl -X POST http://localhost/users/ \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$email\",
            \"username\": \"$username\",
            \"first_name\": \"$firstname\",
            \"last_name\": \"$lastname\",
            \"password\": \"$password\",
            \"role\": \"$role\"
        }"
    echo ""
    print_success "User created successfully"
}

# Frontend logs
frontend_logs() {
    print_header "Frontend Logs (Ctrl+C to exit)"
    docker-compose logs -f astra-learn-front
}

# Frontend bash
frontend_bash() {
    print_header "Opening Frontend Bash"
    docker exec -it astra-learn-front bash
}

# Show container status
show_status() {
    print_header "Container Status"
    docker-compose ps
    echo ""
    print_info "Service URLs:"
    echo "  - Frontend:     http://localhost:3000"
    echo "  - Backend:      http://localhost:8000"
    echo "  - GLOBAL-AUTH:  http://localhost:8001"
    echo "  - Backend DB:   localhost:5434"
}

# Show all logs
show_all_logs() {
    print_header "All Container Logs (Ctrl+C to exit)"
    docker-compose logs -f
}

# Main script logic
check_docker

case "$1" in
    # Setup commands
    init)
        init_project
        ;;
    build)
        build_containers
        ;;
    up)
        start_containers
        ;;
    down)
        stop_containers
        ;;
    restart)
        restart_containers
        ;;
    clean)
        clean_all
        ;;
    
    # Database commands
    migrate)
        run_migrations
        ;;
    makemigrations)
        make_migrations
        ;;
    createsuperuser)
        create_superuser
        ;;
    seed-all)
        seed_all
        ;;
    db-summary)
        db_summary
        ;;
    dbshell)
        db_shell
        ;;
    resetdb)
        reset_db
        ;;
    
    # Backend commands
    shell)
        django_shell
        ;;
    bash)
        backend_bash
        ;;
    logs)
        backend_logs
        ;;
    test)
        run_tests
        ;;
    
    # GLOBAL-AUTH commands
    auth-logs)
        auth_logs
        ;;
    auth-bash)
        auth_bash
        ;;
    create-user)
        create_test_user
        ;;
    
    # Frontend commands
    front-logs)
        frontend_logs
        ;;
    front-bash)
        frontend_bash
        ;;
    
    # Utility commands
    ps)
        docker-compose ps
        ;;
    status)
        show_status
        ;;
    logs-all)
        show_all_logs
        ;;
    help|--help|-h|"")
        show_help
        ;;
    
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
