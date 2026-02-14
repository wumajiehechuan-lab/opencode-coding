#!/usr/bin/env python3
"""
OpenCode Coding - Python module for oh-my-opencode

Usage:
    from opencode_coding import OpenCodeCoding
    
    coder = OpenCodeCoding()
    
    # Normal mode
    session = coder.create_session(title="Fix Bug", mode="normal")
    response = session.send_message("Fix the auth bug", agent="sisyphus")
    
    # Ultrawork mode
    session = coder.create_session(title="Create App", mode="ultrawork")
    session.send_task("Create a Python GUI app", agent="sisyphus")
"""

import requests
import json
import time
import subprocess
import os
from typing import Optional, Dict, List, Any
from dataclasses import dataclass
from datetime import datetime


@dataclass
class CodeController:
    """OpenCode controller configuration."""
    port: int = 4096
    server_host: str = "127.0.0.1"
    working_dir: str = "."
    auto_start: bool = True
    server_timeout: int = 30
    
    @property
    def base_url(self) -> str:
        return f"http://{self.server_host}:{self.port}"


class OpenCodeCoding:
    """
    Main class for controlling oh-my-opencode.
    
    Supports two modes:
    - normal: Multi-turn conversation with step-by-step control
    - ultrawork: Auto-execution until task completion
    """
    
    # API Endpoints (Corrected)
    ENDPOINTS = {
        "health": "/global/health",
        "session": "/session",
        "messages": "/session/{session_id}/messages",
        "message": "/session/{session_id}/message",
        "prompt_async": "/session/{session_id}/prompt_async",
    }
    
    def __init__(
        self,
        port: int = 4096,
        server_host: str = "127.0.0.1",
        working_dir: str = ".",
        auto_start: bool = True
    ):
        """
        Initialize OpenCode Coding controller.
        
        Args:
            port: OpenCode server port
            server_host: OpenCode server host
            working_dir: Working directory for sessions
            auto_start: Auto-start server if not running
        """
        self.controller = CodeController(
            port=port,
            server_host=server_host,
            working_dir=working_dir,
            auto_start=auto_start
        )
        
        if auto_start and not self.is_server_running():
            self.start_server()
    
    def is_server_running(self) -> bool:
        """Check if OpenCode server is running."""
        try:
            url = f"{self.controller.base_url}{self.ENDPOINTS['health']}"
            response = requests.get(url, timeout=2)
            return response.json().get("healthy", False)
        except:
            return False
    
    def start_server(self) -> bool:
        """Start the OpenCode HTTP server."""
        if self.is_server_running():
            print(f"✓ OpenCode server already running at {self.controller.base_url}")
            return True
        
        print(f"Starting OpenCode server on {self.controller.base_url}...")
        
        try:
            # Check if opencode is available
            subprocess.run(["opencode", "--version"], capture_output=True, check=True)
            
            # Start server process
            cmd = [
                "opencode", "serve",
                "--port", str(self.controller.port),
                "--hostname", self.controller.server_host
            ]
            
            subprocess.Popen(
                cmd,
                cwd=self.controller.working_dir,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            
            # Wait for server to be ready
            start_time = time.time()
            while time.time() - start_time < self.controller.server_timeout:
                if self.is_server_running():
                    print(f"✓ OpenCode server started at {self.controller.base_url}")
                    return True
                time.sleep(0.5)
            
            raise TimeoutError("Server failed to respond within timeout period")
            
        except subprocess.CalledProcessError:
            raise RuntimeError("OpenCode not found. Please install: https://opencode.ai")
        except Exception as e:
            raise RuntimeError(f"Failed to start server: {e}")
    
    def _api_call(
        self,
        method: str,
        path: str,
        body: Optional[Dict] = None,
        timeout: int = 30
    ) -> Any:
        """Make API call to OpenCode."""
        url = f"{self.controller.base_url}{path}"
        
        try:
            if method == "GET":
                response = requests.get(url, timeout=timeout)
            elif method == "POST":
                response = requests.post(
                    url,
                    json=body,
                    headers={"Content-Type": "application/json"},
                    timeout=timeout
                )
            elif method == "DELETE":
                response = requests.delete(url, timeout=timeout)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            response.raise_for_status()
            return response.json()
            
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"API request failed: {e}")
    
    def create_session(
        self,
        title: str = "New Session",
        mode: str = "normal",
        agent: str = "sisyphus",
        working_dir: Optional[str] = None
    ) -> "CodeSession":
        """
        Create a new coding session.
        
        Args:
            title: Session title
            mode: "normal" (multi-turn) or "ultrawork" (auto-execute)
            agent: "sisyphus", "librarian", "explore", or "oracle"
            working_dir: Working directory (defaults to controller's dir)
            
        Returns:
            CodeSession object
        """
        body = {
            "title": title,
            "agent": agent
        }
        
        response = self._api_call("POST", self.ENDPOINTS["session"], body)
        
        # Ensure working directory exists
        work_dir = working_dir or self.controller.working_dir
        os.makedirs(work_dir, exist_ok=True)
        
        return CodeSession(
            session_id=response["id"],
            title=title,
            mode=mode,
            agent=agent,
            working_dir=work_dir,
            coding=self
        )
    
    def get_session(self, session_id: str) -> Dict:
        """Get session details."""
        path = f"{self.ENDPOINTS['session']}/{session_id}"
        return self._api_call("GET", path)
    
    def list_sessions(self) -> List[Dict]:
        """List all sessions."""
        return self._api_call("GET", self.ENDPOINTS["session"])
    
    def delete_session(self, session_id: str) -> bool:
        """Delete a session."""
        path = f"{self.ENDPOINTS['session']}/{session_id}"
        self._api_call("DELETE", path)
        print(f"✓ Session deleted: {session_id}")
        return True


class CodeSession:
    """
    Represents an OpenCode coding session.
    
    Provides methods for sending messages and monitoring progress.
    """
    
    def __init__(
        self,
        session_id: str,
        title: str,
        mode: str,
        agent: str,
        working_dir: str,
        coding: OpenCodeCoding
    ):
        self.session_id = session_id
        self.title = title
        self.mode = mode
        self.agent = agent
        self.working_dir = working_dir
        self._coding = coding
    
    def send_message(
        self,
        message: str,
        agent: Optional[str] = None,
        timeout: int = 120
    ) -> Dict:
        """
        Send a message in normal mode (synchronous).
        
        Args:
            message: Message content
            agent: Override agent for this message
            timeout: Timeout in seconds
            
        Returns:
            Response from agent
        """
        body = {
            "parts": [{"type": "text", "text": message}],
            "agent": agent or self.agent
        }
        
        path = self._coding.ENDPOINTS["message"].format(session_id=self.session_id)
        
        print(f"Sending message (timeout: {timeout}s)...")
        return self._coding._api_call("POST", path, body, timeout)
    
    def send_task(
        self,
        task: str,
        agent: Optional[str] = None
    ) -> Dict:
        """
        Send a task in ultrawork mode (asynchronous, auto-execute).
        
        Sisyphus will automatically complete the task without waiting.
        
        Args:
            task: Task description
            agent: Override agent for this task
            
        Returns:
            Status dict
        """
        # Format task for ultrawork mode
        ultrawork_task = f"/ulw\n{task}"
        
        body = {
            "parts": [{"type": "text", "text": ultrawork_task}],
            "agent": agent or self.agent
        }
        
        path = self._coding.ENDPOINTS["prompt_async"].format(session_id=self.session_id)
        
        print("Sending ultrawork task...")
        print("Agent will auto-execute until completion")
        
        try:
            self._coding._api_call("POST", path, body, timeout=10)
        except:
            # Timeout is expected for async
            pass
        
        return {"status": "sent", "mode": "ultrawork", "session_id": self.session_id}
    
    def get_messages(self, last: int = 10) -> List[Dict]:
        """
        Get messages from this session.
        
        Args:
            last: Number of most recent messages to retrieve
            
        Returns:
            List of messages
        """
        path = self._coding.ENDPOINTS["messages"].format(session_id=self.session_id)
        messages = self._coding._api_call("GET", path)
        
        if last > 0 and len(messages) > last:
            return messages[-last:]
        return messages
    
    def watch(self, interval: int = 30, max_iterations: int = 20):
        """
        Monitor session status with periodic polling.
        
        Args:
            interval: Polling interval in seconds
            max_iterations: Maximum number of polling iterations
        """
        print(f"Monitoring session {self.session_id} (interval: {interval}s)...")
        print("Press Ctrl+C to stop")
        
        try:
            for i in range(max_iterations):
                session = self._coding.get_session(self.session_id)
                messages = self.get_messages(last=1)
                
                updated = datetime.fromtimestamp(
                    session["time"]["updated"] / 1000
                ).strftime("%Y-%m-%d %H:%M:%S")
                
                print(f"\n[{i}] Updated: {updated}")
                
                if messages:
                    last_msg = messages[-1]
                    if last_msg.get("parts"):
                        text = last_msg["parts"][0].get("text", "")
                        if len(text) > 100:
                            text = text[:100] + "..."
                        print(f"Last: {text}")
                
                if i < max_iterations - 1:
                    time.sleep(interval)
                    
        except KeyboardInterrupt:
            print("\nMonitoring stopped by user")
    
    def wait_for_completion(
        self,
        timeout: int = 300,
        stability_threshold: int = 60
    ) -> Dict:
        """
        Wait for session to complete (no new messages for stability_threshold seconds).
        
        Args:
            timeout: Maximum wait time in seconds
            stability_threshold: Time without new messages to consider complete
            
        Returns:
            Status dict with 'completed' and 'message_count'
        """
        start_time = time.time()
        last_message_time = start_time
        last_message_count = 0
        
        print(f"Waiting for completion (timeout: {timeout}s)...")
        
        while time.time() - start_time < timeout:
            try:
                messages = self.get_messages(last=100)
                
                if len(messages) != last_message_count:
                    last_message_count = len(messages)
                    last_message_time = time.time()
                    print(".", end="", flush=True)
                else:
                    # Check if stable for threshold time
                    if time.time() - last_message_time > stability_threshold:
                        print(f"\n✓ Session appears complete ({last_message_count} messages)")
                        return {"completed": True, "message_count": last_message_count}
                        
            except Exception as e:
                print("x", end="", flush=True)
            
            time.sleep(5)
        
        print(f"\n⏱ Timeout reached")
        return {"completed": False, "message_count": last_message_count}
    
    def info(self) -> Dict:
        """Get session information."""
        return self._coding.get_session(self.session_id)
    
    def delete(self) -> bool:
        """Delete this session."""
        return self._coding.delete_session(self.session_id)


# Convenience functions

def quick_task(
    task: str,
    working_dir: str = ".",
    agent: str = "sisyphus",
    wait: bool = True
) -> CodeSession:
    """
    Quick function to run an ultrawork task.
    
    Args:
        task: Task description
        working_dir: Working directory
        agent: Agent to use
        wait: Whether to wait for completion
        
    Returns:
        CodeSession object
    """
    coding = OpenCodeCoding(working_dir=working_dir)
    session = coding.create_session(
        title=task[:50],
        mode="ultrawork",
        agent=agent
    )
    session.send_task(task)
    
    if wait:
        session.wait_for_completion()
    
    return session


if __name__ == "__main__":
    # Example usage
    print("OpenCode Coding module loaded.")
    print("\nExample:")
    print("  from opencode_coding import OpenCodeCoding")
    print("  coder = OpenCodeCoding()")
    print("  session = coder.create_session('My Task', mode='ultrawork')")
    print("  session.send_task('Create a Python app')")
