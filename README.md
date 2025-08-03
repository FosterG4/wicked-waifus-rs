# Wicked Waifus (Fork)

![Screenshot](screenshot.png)

## About

**This is a fork of the original Wicked Waifus project** - an Wuthering Waves server emulator written in Rust. 

**Original Repository**: [https://git.xeondev.com/wickedwaifus/wicked-waifus-rs](https://git.xeondev.com/wickedwaifus/wicked-waifus-rs)

This fork has been customized for easier installation and setup with additional environment configurations and improvements. For the most up-to-date version and original development, please visit the original repository.

The goal of this project is to ensure a clean, easy-to-deploy code environment

## Getting started

#### Requirements
- [Rust](https://www.rust-lang.org/tools/install) (latest stable version)
- [PostgreSQL](https://www.postgresql.org/download/) (version 12 or higher)
- [Protoc](https://github.com/protocolbuffers/protobuf/releases) (for protobuf codegen)
- [Git](https://git-scm.com/downloads) (for cloning the repository)
- [Git LFS](https://git-lfs.github.com/) (for large file handling)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (optional, for containerized setup)

#### Environment Setup

Before starting, ensure your environment is properly configured:

1. **Rust Environment**:
   ```sh
   # Install Rust if not already installed
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source ~/.cargo/env
   
   # Update Rust to latest version
   rustup update
   ```

2. **PostgreSQL Setup**:
   ```sh
   # Create database (adjust credentials as needed)
   createdb wicked_waifus_db
   # Or using psql:
   psql -U postgres -c "CREATE DATABASE wicked_waifus_db;"
   ```

3. **Protobuf Compiler**:
   ```sh
   # On Ubuntu/Debian
   sudo apt install protobuf-compiler
   
   # On macOS
   brew install protobuf
   
   # On Windows (using Chocolatey)
   choco install protoc
   ```

4. **Git LFS Setup** (for large game data files):
   ```sh
   # Install Git LFS
   git lfs install
   
   # Track large JSON files
   git lfs track "*.json"
   git lfs track "data/assets/**/*.json"
   git lfs track "assets/**/*.json"
   ```

#### Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=wicked_waifus_db

# Server Ports
CONFIG_SERVER_PORT=8080
LOGIN_SERVER_PORT=8081
GATEWAY_SERVER_PORT=8082
GAME_SERVER_PORT=8083

# Development Settings
RUST_LOG=info
RUST_BACKTRACE=1

# Optional: Custom paths
DATA_PATH=./data
CONFIG_PATH=./config
```

#### Setup Options

##### Option A: Building from sources (Recommended)

```sh
# Clone this fork with LFS files
git clone --recursive https://github.com/FosterG4/wicked-waifus-rs.git
cd wicked-waifus-rs

# Pull LFS files
git lfs pull

# Build all dependencies
cargo build --release

# Run servers (in separate terminals)
cargo run --bin wicked-waifus-config-server
cargo run --bin wicked-waifus-login-server
cargo run --bin wicked-waifus-gateway-server
cargo run --bin wicked-waifus-game-server
```

##### Option B: Docker setup (Easier for beginners)

If you prefer a containerized setup, you can use Docker:

```sh
# Clone the repository
git clone --recursive https://github.com/FosterG4/wicked-waifus-rs.git
cd wicked-waifus-rs

# Pull LFS files
git lfs pull

# Build Docker images
# On Windows:
builder.bat
# On Linux/macOS:
./builder.sh

# Start all services
docker compose up -d

# Check service status
docker compose ps
```

##### Option C: Using pre-built binaries

Navigate to the [Releases](https://git.xeondev.com/wickedwaifus/wicked-waifus-rs/releases) page and download the latest release for your platform.

Launch all servers in separate terminals:
```sh
./wicked-waifus-config-server
./wicked-waifus-login-server
./wicked-waifus-gateway-server
./wicked-waifus-game-server
```

**Note**: You don't need to install Rust and Protoc if using pre-built binaries, though building from sources is preferred for better compatibility and customization.

#### Configuration

Each server creates its own configuration file in the current working directory upon first startup. You'll need to configure these files with your specific settings.

##### Database Configuration

Configure PostgreSQL credentials in each server's config file:

```toml
[database]
host = "localhost:5432"
user_name = "postgres"
password = "your_password"
db_name = "wicked_waifus_db"
```

**Important**: Make sure to create the database `wicked_waifus_db` before starting the servers. You can do this using PgAdmin or the command line.

##### Server Configuration Files

The following configuration files will be created in your working directory:
- `configserver.toml` - Configuration server settings
- `loginserver.toml` - Login server settings  
- `gateway.toml` - Gateway server settings
- `gameserver.toml` - Game server settings

#### Data Files

The repository includes necessary data files managed by Git LFS:
- Logic JSON collections (`data/assets/game-data/BinData`)
- Config/hotpatch indexes (`data/assets/config-server`, `data/assets/hotpatch-server`)

**Important**: Large files are managed by Git LFS. After cloning, run `git lfs pull` to download all large files.

#### Client Setup

To connect to your server:

1. Download Wuthering Waves Beta 2.1 client
2. Apply the [wicked-waifus-win-patch](https://git.xeondev.com/wickedwaifus/wicked-waifus-win-patch/releases)
3. Add necessary `.pak` files from [wicked-waifus-pak](https://git.xeondev.com/wickedwaifus/wicked-waifus-pak)

#### Development Tools

This fork includes additional development tools:

- **Database Manager**: `db-manager.ps1` - PowerShell script for database management
- **Environment Example**: `.env.example` - Template for environment variables
- **Cursor Rules**: `.cursor/rules/` - Development guidelines and project structure

### Troubleshooting

- **Build Issues**: Ensure you have the latest Rust toolchain and all dependencies installed
- **Database Connection**: Verify PostgreSQL is running and credentials are correct
- **Port Conflicts**: Check that required ports are not in use by other applications
- **LFS Issues**: Run `git lfs pull` if large files are missing
- **Environment Variables**: Ensure `.env` file is properly configured
- **For additional help**: [Visit the original project's Discord](https://discord.gg/reversedrooms)

### Support

This is a community fork. For official support and updates, please visit the [original repository](https://git.xeondev.com/wickedwaifus/wicked-waifus-rs).

If you want to support the original project, feel free to [send a tip via boosty](https://boosty.to/xeondev/donate)