#!/usr/bin/env python3
"""
BlackRoad OS - Complete System with Boot Sequence

Full integration: boot → persistence → main loop
"""

import time
import sys
import signal
import os

def main():
    """Main with boot sequence"""
    
    # Check for headless mode
    headless = '--headless' in sys.argv or os.environ.get('BLACKROAD_HEADLESS') == '1'
    
    # Import all layers
    try:
        from blackroad_engine import create_initial_state, update_live_metrics
        from blackroad_renderer import render
        from blackroad_input_router import create_input_router, poll_input
        from blackroad_command_executor import handle_event, update_agent_lifecycle
        from blackroad_persistence import load_state, save_state, ensure_persistence_dirs
        from blackroad_boot_sequence import run_boot_sequence
    except ImportError as e:
        print(f"✗ Import error: {e}")
        print(f"  Make sure all BlackRoad OS modules are in the same directory")
        sys.exit(1)
    
    # Ensure persistence directories exist
    ensure_persistence_dirs()
    
    # Try to load previous state
    state = load_state()
    
    if state:
        # Restored previous session
        pass
    else:
        # Starting fresh
        state = create_initial_state()
    
    # ================================
    # RUN BOOT SEQUENCE
    # ================================
    
    try:
        run_boot_sequence(state, skip=headless)
    except KeyboardInterrupt:
        print("\nBoot interrupted.")
        sys.exit(0)
    except Exception as e:
        print(f"\nBoot sequence error: {e}")
        print("Starting main loop anyway...")
        time.sleep(1)
    
    # ================================
    # MAIN EVENT LOOP
    # ================================
    
    # Initialize input router
    router = create_input_router()
    
    # Setup graceful shutdown
    def shutdown_handler(signum, frame):
        """Save on exit"""
        print("\nShutting down...")
        save_state(state)
        print("State saved. Goodbye.")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, shutdown_handler)
    signal.signal(signal.SIGTERM, shutdown_handler)
    
    # Initial render
    width, height = 120, 40
    output = render(state, width, height)
    print(output)
    
    last_metrics_update = time.time()
    last_agent_update = time.time()
    
    # Main loop
    try:
        while state.get('running', True):
            # Poll for input (non-blocking)
            event = poll_input(router)
            
            if event:
                # Handle event
                state = handle_event(event, state)
            
            # Update live metrics (every 1 second)
            current_time = time.time()
            if current_time - last_metrics_update >= 1.0:
                state = update_live_metrics(state)
                last_metrics_update = current_time
            
            # Update agent lifecycle
            if current_time - last_agent_update >= 0.5:
                state = update_agent_lifecycle(state)
                last_agent_update = current_time
            
            # Render if dirty
            if state.get('dirty', False):
                output = render(state, width, height)
                print(output)
                state['dirty'] = False
            
            # Small sleep to avoid CPU spin
            time.sleep(0.01)
    
    except KeyboardInterrupt:
        pass
    
    # Save on exit
    print("\n\nShutting down...")
    save_state(state)
    print("State saved. Goodbye.")

if __name__ == "__main__":
    main()
