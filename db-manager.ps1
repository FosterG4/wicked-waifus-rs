# =============================================================================
# Wicked Waifus Database Manager
# =============================================================================
# This script provides various database management operations

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("clean", "reset", "backup", "restore", "status", "migrate", "help")]
    [string]$Action = "help"
)

# Load environment variables if .env file exists
if (Test-Path ".env") {
    Write-Host "Loading environment variables from .env file..." -ForegroundColor Cyan
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^#][^=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Get database configuration from environment or use defaults
$DB_HOST = $env:DB_HOST ?? "localhost:5432"
$DB_USERNAME = $env:DB_USERNAME ?? "postgres"
$DB_PASSWORD = $env:DB_PASSWORD ?? ""
$DB_NAME = $env:DB_NAME ?? "shorekeeper"

# Function to execute SQL command
function Invoke-PostgreSQL {
    param(
        [string]$Command,
        [string]$Database = $DB_NAME
    )
    
    $env:PGPASSWORD = $DB_PASSWORD
    $dbHost, $dbPort = $DB_HOST -split ":"
    
    try {
        $result = psql -h $dbHost -p $dbPort -U $DB_USERNAME -d $Database -c $Command 2>&1
        return $result
    }
    catch {
        Write-Host "Error executing PostgreSQL command: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to check PostgreSQL connection
function Test-PostgreSQLConnection {
    $testResult = Invoke-PostgreSQL "SELECT version();" "postgres"
    if ($testResult -and $testResult -notmatch "error") {
        return $true
    }
    return $false
}

# Function to clean database (truncate tables)
function Clear-Database {
    Write-Host "Cleaning database tables..." -ForegroundColor Cyan
    
    $cleanupCommands = @(
        "TRUNCATE TABLE IF EXISTS t_user_account CASCADE;",
        "TRUNCATE TABLE IF EXISTS t_user_uid CASCADE;",
        "TRUNCATE TABLE IF EXISTS t_player_data CASCADE;"
    )
    
    foreach ($command in $cleanupCommands) {
        $cleanupResult = Invoke-PostgreSQL $command
        if ($cleanupResult -and $cleanupResult -notmatch "error") {
            Write-Host "  ✓ Cleaned table data" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Failed to clean table" -ForegroundColor Red
        }
    }
    
    # Reset sequences
    $resetResult = Invoke-PostgreSQL "SELECT setval(pg_get_serial_sequence('t_user_uid', 'player_id'), 1, false);"
    if ($resetResult -and $resetResult -notmatch "error") {
        Write-Host "✓ Reset sequences" -ForegroundColor Green
    }
}

# Function to reset database (drop and recreate)
function Reset-Database {
    Write-Host "Resetting database..." -ForegroundColor Yellow
    
    # Drop and recreate database
    Write-Host "Dropping existing database..." -ForegroundColor Cyan
    $dropResult = Invoke-PostgreSQL "DROP DATABASE IF EXISTS $DB_NAME;" "postgres"
    if ($dropResult -and $dropResult -notmatch "error") {
        Write-Host "✓ Dropped existing database" -ForegroundColor Green
    }
    
    Write-Host "Creating fresh database..." -ForegroundColor Cyan
    $createResult = Invoke-PostgreSQL "CREATE DATABASE $DB_NAME;" "postgres"
    if ($createResult -and $createResult -notmatch "error") {
        Write-Host "✓ Created fresh database" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create database" -ForegroundColor Red
        return
    }
    
    # Run migrations
    Write-Host "Running database migrations..." -ForegroundColor Cyan
    if (Test-Path "wicked-waifus-database/migrations") {
        $migrationFiles = Get-ChildItem "wicked-waifus-database/migrations" -Filter "*.sql" | Sort-Object Name
        
        foreach ($migration in $migrationFiles) {
            Write-Host "  Running migration: $($migration.Name)" -ForegroundColor White
            $sqlContent = Get-Content $migration.FullName -Raw
            $migrationResult = Invoke-PostgreSQL $sqlContent
            if ($migrationResult -and $migrationResult -notmatch "error") {
                Write-Host "    ✓ Success" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Failed" -ForegroundColor Red
            }
        }
    }
}

# Function to backup database
function Backup-Database {
    param([string]$BackupPath = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql")
    
    Write-Host "Creating database backup..." -ForegroundColor Cyan
    Write-Host "Backup file: $BackupPath" -ForegroundColor White
    
    $env:PGPASSWORD = $DB_PASSWORD
    $dbHost, $dbPort = $DB_HOST -split ":"
    
    try {
        pg_dump -h $dbHost -p $dbPort -U $DB_USERNAME -d $DB_NAME -f $BackupPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Database backup created successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to create backup" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error creating backup: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to restore database
function Restore-Database {
    param([Parameter(Mandatory=$true)][string]$BackupPath)
    
    if (-not (Test-Path $BackupPath)) {
        Write-Host "Backup file not found: $BackupPath" -ForegroundColor Red
        return
    }
    
    Write-Host "Restoring database from backup..." -ForegroundColor Cyan
    Write-Host "Backup file: $BackupPath" -ForegroundColor White
    
    $env:PGPASSWORD = $DB_PASSWORD
    $host, $port = $DB_HOST -split ":"
    
    try {
        psql -h $host -p $port -U $DB_USERNAME -d $DB_NAME -f $BackupPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Database restored successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to restore database" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error restoring database: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to show database status
function Show-DatabaseStatus {
    Write-Host "Database Status:" -ForegroundColor Cyan
    Write-Host "  Host: $DB_HOST" -ForegroundColor White
    Write-Host "  Username: $DB_USERNAME" -ForegroundColor White
    Write-Host "  Database: $DB_NAME" -ForegroundColor White
    
    if (Test-PostgreSQLConnection) {
        Write-Host "  Connection: ✓ Connected" -ForegroundColor Green
        
        # Check if database exists
        $dbExists = Invoke-PostgreSQL "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME';" "postgres"
        if ($dbExists -and $dbExists -notmatch "error") {
            Write-Host "  Database: ✓ Exists" -ForegroundColor Green
            
            # Get table count
            $tableCount = Invoke-PostgreSQL "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
            Write-Host "  Tables: $tableCount" -ForegroundColor White
            
            # Get row counts
            $userAccountCount = Invoke-PostgreSQL "SELECT COUNT(*) FROM t_user_account;"
            $userUidCount = Invoke-PostgreSQL "SELECT COUNT(*) FROM t_user_uid;"
            $playerDataCount = Invoke-PostgreSQL "SELECT COUNT(*) FROM t_player_data;"
            Write-Host "  User Accounts: $userAccountCount" -ForegroundColor White
            Write-Host "  User UIDs: $userUidCount" -ForegroundColor White
            Write-Host "  Player Data: $playerDataCount" -ForegroundColor White
        } else {
            Write-Host "  Database: ✗ Does not exist" -ForegroundColor Red
        }
    } else {
        Write-Host "  Connection: ✗ Failed" -ForegroundColor Red
    }
}

# Function to run migrations
function Invoke-Migrations {
    Write-Host "Running database migrations..." -ForegroundColor Cyan
    
    if (Test-Path "wicked-waifus-database/migrations") {
        $migrationFiles = Get-ChildItem "wicked-waifus-database/migrations" -Filter "*.sql" | Sort-Object Name
        
        foreach ($migration in $migrationFiles) {
            Write-Host "  Running migration: $($migration.Name)" -ForegroundColor White
            $sqlContent = Get-Content $migration.FullName -Raw
            $migrationResult = Invoke-PostgreSQL $sqlContent
            if ($migrationResult -and $migrationResult -notmatch "error") {
                Write-Host "    ✓ Success" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Failed" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No migration files found" -ForegroundColor Yellow
    }
}

# Function to show help
function Show-Help {
    Write-Host "Wicked Waifus Database Manager" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\db-manager.ps1 [-Action <action>]" -ForegroundColor White
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Cyan
    Write-Host "  clean    - Clean database tables (truncate data)" -ForegroundColor White
    Write-Host "  reset    - Reset database (drop and recreate)" -ForegroundColor White
    Write-Host "  backup   - Create database backup" -ForegroundColor White
    Write-Host "  restore  - Restore database from backup" -ForegroundColor White
    Write-Host "  status   - Show database status" -ForegroundColor White
    Write-Host "  migrate  - Run database migrations" -ForegroundColor White
    Write-Host "  help     - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\db-manager.ps1 -Action clean" -ForegroundColor White
    Write-Host "  .\db-manager.ps1 -Action backup" -ForegroundColor White
    Write-Host "  .\db-manager.ps1 -Action status" -ForegroundColor White
}

# Main execution
Write-Host "Wicked Waifus Database Manager" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    "clean" {
        if (Test-PostgreSQLConnection) {
            Clear-Database
            Write-Host "✓ Database cleaned successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Cannot connect to PostgreSQL" -ForegroundColor Red
        }
    }
    "reset" {
        if (Test-PostgreSQLConnection) {
            Reset-Database
            Write-Host "✓ Database reset successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Cannot connect to PostgreSQL" -ForegroundColor Red
        }
    }
    "backup" {
        if (Test-PostgreSQLConnection) {
            Backup-Database
        } else {
            Write-Host "✗ Cannot connect to PostgreSQL" -ForegroundColor Red
        }
    }
    "restore" {
        Write-Host "Please specify backup file path:" -ForegroundColor Yellow
        $backupPath = Read-Host "Backup file path"
        if (Test-PostgreSQLConnection) {
            Restore-Database -BackupPath $backupPath
        } else {
            Write-Host "✗ Cannot connect to PostgreSQL" -ForegroundColor Red
        }
    }
    "status" {
        Show-DatabaseStatus
    }
    "migrate" {
        if (Test-PostgreSQLConnection) {
            Invoke-Migrations
            Write-Host "✓ Migrations completed" -ForegroundColor Green
        } else {
            Write-Host "✗ Cannot connect to PostgreSQL" -ForegroundColor Red
        }
    }
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
} 