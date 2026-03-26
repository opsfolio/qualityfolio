#!/usr/bin/env python3
"""
GitHub Singer Tap Capturable Executable for surveilr
"""

import os
import sys
import json
import subprocess
import tempfile
import logging
from pathlib import Path
from typing import Dict, Any, Optional

# =============================================================================
# CONFIGURATION SECTION - LOADED FROM .env FILE
# =============================================================================
def cleanup_generated_files(script_dir: Path):
    """Remove generated tap files if they exist"""
    files_to_remove = [
        "tap-github-config.json",
        "tap-github-properties.json",
        "tap-github-state.json",
    ]

    for filename in files_to_remove:
        file_path = script_dir / filename
        if file_path.exists():
            file_path.unlink()          


def load_config_hybrid() -> Dict[str, Any]:
    """Load configuration from .env (credentials) and stdin (dynamic dates/sessions)"""
    script_dir = Path(__file__).parent
    env_file = script_dir / ".env"
    
    # Default config
    config = {
        "access_token": "",
        "repository": "",
        "start_date": "2023-01-01T00:00:00Z"
    }
    
    # Load static credentials from .env file
    if env_file.exists():
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    
                    if key == "GITHUB_ACCESS_TOKEN":
                        config["access_token"] = value
                    elif key == "GITHUB_REPOSITORY":
                        config["repository"] = value
                    elif key == "GITHUB_START_DATE":
                        config["start_date"] = value  # Allow override from .env
    
    # Check for dynamic date/session data from stdin
    if not sys.stdin.isatty():
        try:
            stdin_content = sys.stdin.read().strip()
            if stdin_content:
                stdin_data = json.loads(stdin_content)
                
                # Extract dynamic start date from session context
                if "github_start_date" in stdin_data:
                    config["start_date"] = stdin_data["github_start_date"]
                elif "start_date" in stdin_data:
                    config["start_date"] = stdin_data["start_date"]
                # Extract date from surveilr session context if available
                elif "surveilr-ingest" in stdin_data:
                    session_data = stdin_data["surveilr-ingest"]
                    if "session" in session_data and "start_date" in session_data["session"]:
                        config["start_date"] = session_data["session"]["start_date"]
                    
        except (json.JSONDecodeError, KeyError) as e:
            logger = logging.getLogger("tap-github")
            logger.warning(f"Failed to parse stdin session data: {e}. Using .env/default date.")
    
    return config

CONFIG = load_config_hybrid()

SELECTED_STREAMS = [
    "issues",
    "pull_requests",
    "commits", 
    "comments",
    "releases"
]

TAP_NAME = "tap-github"
INSTALL_CMD = ["pip", "install", "pipelinewise-tap-github"]

# =============================================================================
# SCRIPT IMPLEMENTATION
# =============================================================================

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='[tap-github] %(levelname)s: %(message)s',
        stream=sys.stderr
    )
    return logging.getLogger("tap-github")

def setup_virtual_environment(script_dir: Path) -> Path:
    """Setup or use existing virtual environment for tap installation"""
    logger = logging.getLogger("tap-github")
    venv_path = script_dir / ".tap-venv"
    
    if not venv_path.exists():
        logger.info("Creating virtual environment...")
        try:
            subprocess.run([sys.executable, "-m", "venv", str(venv_path)], check=True, capture_output=True)
            logger.info("Virtual environment created successfully")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to create virtual environment: {e}")
            raise
    
    return venv_path

def install_tap(venv_path: Path):
    """Install the tap in virtual environment if not already installed"""
    logger = logging.getLogger("tap-github")
    
    # Check if we're in a virtual environment or use our created one
    if "VIRTUAL_ENV" in os.environ:
        pip_cmd = "pip3"
        python_cmd = "python3"
        logger.info("Using existing virtual environment")
    else:
        # Use our virtual environment
        if os.name == 'nt':  # Windows
            pip_cmd = str(venv_path / "Scripts" / "pip")
            python_cmd = str(venv_path / "Scripts" / "python")
        else:  # Unix/Linux/macOS
            pip_cmd = str(venv_path / "bin" / "pip")
            python_cmd = str(venv_path / "bin" / "python")
        logger.info(f"Using virtual environment at {venv_path}")
    
    # Check if tap is already installed in the environment
    try:
        result = subprocess.run([python_cmd, "-c", f"import {TAP_NAME.replace('-', '_')}"], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            logger.info(f"{TAP_NAME} already installed in environment")
            return
    except:
        pass
    
    logger.info(f"Installing {TAP_NAME} in virtual environment...")
    try:
        # Upgrade pip and install dependencies
        subprocess.run([pip_cmd, "install", "--upgrade", "pip"], check=True, capture_output=True)
        # Install required dependencies first
        subprocess.run([pip_cmd, "install", "pytz", "singer-python"], check=True, capture_output=True)
        subprocess.run([pip_cmd, "install", "pipelinewise-tap-github"], check=True, capture_output=True)
        # Upgrade urllib3 and requests to fix six module conflicts
        subprocess.run([pip_cmd, "install", "--upgrade", "urllib3", "requests"], check=True, capture_output=True)
        logger.info(f"{TAP_NAME} installed successfully")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install {TAP_NAME}: {e}")
        raise

def find_tap_binary(script_dir: Path):
    """Find the tap binary in various locations"""
    # Check environment variable
    if "TAP_GITHUB_BIN" in os.environ:
        return os.environ["TAP_GITHUB_BIN"]
    
    # Check current virtual environment
    if "VIRTUAL_ENV" in os.environ:
        venv_path = Path(os.environ["VIRTUAL_ENV"]) / "bin" / TAP_NAME
        if venv_path.exists():
            return str(venv_path)
    
    # Check our local virtual environment
    local_venv_path = script_dir / ".tap-venv" / "bin" / TAP_NAME
    if local_venv_path.exists():
        return str(local_venv_path)
    
    # Check common tap environment
    tap_env_path = Path.home() / ".singer-taps-env" / "bin" / TAP_NAME
    if tap_env_path.exists():
        return str(tap_env_path)
    
    # Check system PATH
    try:
        result = subprocess.run(["which", TAP_NAME], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    except:
        pass
    
    # Setup virtual environment and install tap
    venv_path = setup_virtual_environment(script_dir)
    install_tap(venv_path)
    
    # Check again after installation
    local_venv_binary = venv_path / "bin" / TAP_NAME
    if local_venv_binary.exists():
        return str(local_venv_binary)
    
    raise FileNotFoundError(f"{TAP_NAME} not found even after installation")

def create_config_file(script_dir: Path) -> Path:
    """Create the tap configuration file"""
    config_file = script_dir / "tap-github-config.json"
    
    # Use environment variable override if available
    if "TAP_GITHUB_CONFIG" in os.environ:
        config_file = Path(os.environ["TAP_GITHUB_CONFIG"])
        if config_file.exists():
            return config_file
    
    with open(config_file, 'w') as f:
        json.dump(CONFIG, f, indent=2)
    
    return config_file

def create_state_file(script_dir: Path) -> Path:
    """Initialize state file if it doesn't exist"""
    state_file = script_dir / "tap-github-state.json"
    
    # Use environment variable override if available
    if "TAP_GITHUB_STATE" in os.environ:
        state_file = Path(os.environ["TAP_GITHUB_STATE"])
    
    if not state_file.exists():
        with open(state_file, 'w') as f:
            json.dump({}, f)
    
    return state_file

def discover_and_select_streams(script_dir: Path, config_file: Path) -> Path:
    """Discover available streams and select configured ones"""
    properties_file = script_dir / f"{TAP_NAME}-properties.json"
    
    # Use environment variable override if available
    if "TAP_GITHUB_PROPERTIES" in os.environ:
        properties_path = os.environ["TAP_GITHUB_PROPERTIES"]
        # Handle relative paths by resolving from script directory
        if not properties_path.startswith('/'):
            properties_file = script_dir / properties_path
        else:
            properties_file = Path(properties_path)
        if properties_file.exists():
            return properties_file
    
    if properties_file.exists():
        logging.info("Properties file already exists, skipping discovery")
        return properties_file

    logger = logging.getLogger("tap-github")
    logger.info("Discovering available streams...")
    
    tap_binary = find_tap_binary(script_dir)
    
    try:
        result = subprocess.run([
            tap_binary,
            "--config", str(config_file),
            "--discover"
        ], capture_output=True, text=True, check=True)
        
        catalog = json.loads(result.stdout)
        
        # Select configured streams using Singer catalog metadata format
        selected_streams = set(SELECTED_STREAMS)
        for stream in catalog.get("streams", []):
            stream_id = stream.get("tap_stream_id")
            is_selected = stream_id in selected_streams
            
            # Use proper Singer catalog metadata format
            if "metadata" not in stream:
                stream["metadata"] = []
            
            # Add selection metadata at root level (breadcrumb: [])
            stream["metadata"].append({
                "breadcrumb": [],
                "metadata": {
                    "selected": is_selected,
                    "inclusion": "available"
                }
            })
            
            if is_selected:
                logger.info(f"Selected stream: {stream_id}")
        
        # Write properties file
        with open(properties_file, 'w') as f:
            json.dump(catalog, f, indent=2)
            
        return properties_file
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to discover streams: {e}")
        logger.error(f"stderr: {e.stderr}")
        raise

def run_tap(config_file: Path, properties_file: Path, state_file: Path, script_dir: Path):
    """Execute the Singer tap"""
    logger = logging.getLogger("tap-github")
    logger.info(f"Config: {config_file}")
    logger.info(f"Properties: {properties_file}")
    
    tap_binary = find_tap_binary(script_dir)
    
    cmd = [
        tap_binary,
        "--config", str(config_file),
        "--properties", str(properties_file), 
        "--state", str(state_file)
    ]
    
    try:
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as state_temp:
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Process stdout line by line
            for line in process.stdout:
                line = line.strip()
                if line:
                    # Write to stdout for surveilr ingestion
                    print(line)
                    sys.stdout.flush()
                    
                    # Extract state messages
                    try:
                        message = json.loads(line)
                        if message.get("type") == "STATE":
                            state_temp.write(json.dumps(message.get("value", {})) + '\n')
                            state_temp.flush()
                    except json.JSONDecodeError:
                        pass
            
            # Log stderr output
            for line in process.stderr:
                logger.info(line.strip())
            
            # Wait for process to complete
            return_code = process.wait()
            
            if return_code != 0:
                logger.error(f"Tap failed with return code {return_code}")
                raise subprocess.CalledProcessError(return_code, cmd)
            
            # Update state file with last state
            state_temp.seek(0)
            lines = state_temp.readlines()
            if lines:
                last_state = lines[-1].strip()
                if last_state:
                    with open(state_file, 'w') as f:
                        f.write(last_state)
                    logger.info("State updated")
            
            os.unlink(state_temp.name)
            
    except Exception as e:
        logger.error(f"Failed to run tap: {e}")
        raise

def main():
    logger = setup_logging()
    script_dir = Path(__file__).parent
    cleanup_generated_files(script_dir)
    try:
        logger.info("Starting GitHub tap extraction")
        
        # Setup files
        config_file = create_config_file(script_dir)
        state_file = create_state_file(script_dir)
        properties_file = discover_and_select_streams(script_dir, config_file)
        
        # Run tap
        run_tap(config_file, properties_file, state_file, script_dir)
        
        logger.info("Ingestion complete")
        
    except Exception as e:
        logger.error(f"Tap execution failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()