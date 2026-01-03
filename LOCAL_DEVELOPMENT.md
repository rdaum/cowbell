# Local Development Guide

This guide covers setting up and running Cowbell locally with a mooR server.

## Development Workflows

There are two main workflows for local development:

1. **Full Stack (Recommended)** - Run Cowbell as a core within the mooR development environment, with web frontend, telnet, and all services
2. **Standalone Daemon** - Run just the mooR daemon directly, useful for minimal testing or debugging

---

## Full Stack Workflow (Recommended)

This is the preferred workflow for most development. It runs Cowbell within the mooR docker-compose environment with full web UI, telnet access, and hot reloading.

### Setup

1. Clone mooR and checkout Cowbell under `cores/`:
   ```bash
   git clone https://codeberg.org/timbran/moor.git
   cd moor
   git clone https://codeberg.org/timbran/cowbell.git cores/cowbell
   ```

2. Start the full development stack:
   ```bash
   rm -rf moor-data && MOOR_CORE=cores/cowbell/src npm run full:dev
   ```

This brings up:
- mooR daemon with Cowbell loaded
- Web frontend with Vite hot reloading
- Telnet host on port 8888
- Web host on port 8080

### Development Cycle

After making changes to `cores/cowbell/src/`:

```bash
# Stop the stack (Ctrl+C)
rm -rf moor-data && MOOR_CORE=cores/cowbell/src npm run full:dev
```

---

## Standalone Daemon Workflow

Use this workflow when you need to run just the daemon without the full stack, or when working on Cowbell in isolation.

### Prerequisites

1. **mooR source checkout** - If not using the recommended cores/ layout, clone mooR:
   ```bash
   git clone https://codeberg.org/timbran/moor.git ../..
   cd ../..
   cargo build --release -p moorc -p moor-daemon
   ```

   Or if cowbell is standalone (not in cores/), set `MOOR_DIR` in `.env.mk`.

2. **Rust toolchain** - Required for `cargo` build mode

### Configuration

Create `.env.mk` in the project root to override defaults:

```makefile
# Path to mooR source (default: ../.. for cores/cowbell/ layout)
MOOR_DIR = /path/to/moor

# Build profile: debug or release (default: debug)
BUILD_PROFILE = release

# Daemon data directory (default: local-daemon-data)
DATA_DIR = my-data

# Database name (default: development.db)
DB_NAME = mydb.db
```

### Build Modes

Set `MOORC_TYPE` to choose how moorc runs:

| Mode | Description |
|------|-------------|
| `cargo` (default) | Runs `cargo run -p moorc` from MOOR_DIR |
| `direct` | Uses pre-built binary at `$(MOOR_DIR)/target/$(BUILD_PROFILE)/moorc` |
| `docker` | Runs moorc in Docker container |

### Development Cycle

#### 1. Build the database

```bash
make gen.objdir
```

This compiles `src/` into `gen.objdir/`.

#### 2. Start the daemon

```bash
make start
```

The daemon runs in the background. A PID file (`.moor-daemon.pid`) tracks the process.

**Note**: This starts only the daemon. For telnet/web access, you'll need to start those hosts separately or use the Full Stack workflow.

#### 3. Connect and develop

Connect to the daemon using:
- MCP tools
- Direct RPC via IPC sockets in `moor-ipc/`

#### 4. Stop the daemon

```bash
make stop
```

#### Full rebuild cycle

After making changes to `src/`:

```bash
make stop           # Stop running daemon
make rebuild        # Recompile and update src/
make start          # Restart daemon with new code
```

---

## Makefile Targets

| Target | Description |
|--------|-------------|
| `gen.objdir` | Compile src/ to gen.objdir/ |
| `gen.moo-textdump` | Generate old-style textdump |
| `rebuild` | Compile and copy back to src/ (destructive) |
| `test` | Run test suite |
| `start` | Start moor-daemon in background |
| `stop` | Stop running daemon |
| `status` | Check if daemon is running |
| `clean` | Remove generated files |

## Daemon Script

The daemon is managed by `scripts/daemon.sh`, which handles mode-aware command construction.

```bash
# Direct usage
./scripts/daemon.sh start
./scripts/daemon.sh stop
./scripts/daemon.sh status
./scripts/daemon.sh help
```

## Environment Variables

All variables can be set via environment or `.env.mk`:

### Compiler Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MOOR_DIR` | `../..` | Path to mooR source (cores/cowbell/ layout) |
| `BUILD_PROFILE` | `debug` | Build profile (debug/release) |
| `MOORC_TYPE` | `cargo` | Build mode (cargo/direct/docker) |
| `DEBUG` | `0` | Set to 1 to run moorc under gdb |

### Daemon Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `local-daemon-data` | Daemon database directory |
| `DB_NAME` | `development.db` | Database filename |
| `IPC_DIR` | `moor-ipc` | IPC socket directory |
| `PID_FILE` | `.moor-daemon.pid` | PID file location |
