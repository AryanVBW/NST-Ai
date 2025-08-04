from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import json
import subprocess
import psutil
import os
import signal
import time
from datetime import datetime

from nst_ai.utils.auth import get_verified_user, get_admin_user

router = APIRouter()

# Workflow process management
workflow_processes = {}

############################
# Models
############################

class WorkflowConfig(BaseModel):
    enabled: bool = False
    auto_start: bool = False
    port: Optional[int] = 5678
    host: Optional[str] = "0.0.0.0"
    webhook_url: Optional[str] = None

class WorkflowResponse(BaseModel):
    id: str
    name: str
    active: bool
    created_at: str
    updated_at: str
    nodes: List[Dict[str, Any]]
    connections: Dict[str, Any]

class WorkflowExecuteRequest(BaseModel):
    workflow_id: str
    input_data: Optional[Dict[str, Any]] = None

class WorkflowStatusResponse(BaseModel):
    status: str  # "running", "stopped", "error"
    process_id: Optional[int] = None
    uptime: Optional[str] = None
    port: Optional[int] = None
    url: Optional[str] = None

############################
# Workflow Configuration
############################

@router.get("/config")
async def get_workflow_config(user=Depends(get_admin_user)):
    """Get current workflow system configuration"""
    # In a real implementation, this would be stored in database
    config = {
        "enabled": True,
        "auto_start": False,
        "port": 5678,
        "host": "0.0.0.0",
        "webhook_url": "http://localhost:5678/webhook"
    }
    return WorkflowConfig(**config)

@router.post("/config")
async def update_workflow_config(
    config: WorkflowConfig, 
    user=Depends(get_admin_user)
):
    """Update workflow system configuration"""
    try:
        # Store configuration (in real implementation, save to database)
        # For now, we'll just return the updated config
        return {
            "success": True,
            "config": config.dict(),
            "message": "Workflow configuration updated successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update configuration: {str(e)}")

############################
# Workflow Management
############################

@router.get("/status")
async def get_workflow_status(user=Depends(get_admin_user)):
    """Get workflow system status"""
    try:
        # Check if workflow server is running
        status = "stopped"
        process_id = None
        uptime = None
        
        # Check for existing processes
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if proc.info['cmdline'] and any('n8n' in str(cmd) for cmd in proc.info['cmdline']):
                    status = "running"
                    process_id = proc.info['pid']
                    # Calculate uptime
                    create_time = proc.create_time()
                    uptime = str(datetime.now() - datetime.fromtimestamp(create_time))
                    break
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        return WorkflowStatusResponse(
            status=status,
            process_id=process_id,
            uptime=uptime,
            port=5678,
            url="http://localhost:5678" if status == "running" else None
        )
    except Exception as e:
        return WorkflowStatusResponse(
            status="error",
            process_id=None,
            uptime=None,
            port=None,
            url=None
        )

@router.post("/start")
async def start_workflow_server(
    background_tasks: BackgroundTasks,
    user=Depends(get_admin_user)
):
    """Start the workflow server"""
    try:
        # Check if already running
        status = await get_workflow_status(user)
        if status.status == "running":
            return {"success": True, "message": "Workflow server is already running", "status": status}
        
        # Start workflow server in background
        background_tasks.add_task(start_workflow_process)
        
        # Wait a moment for process to start
        time.sleep(2)
        
        # Check status again
        new_status = await get_workflow_status(user)
        
        return {
            "success": True,
            "message": "Workflow server start initiated",
            "status": new_status
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start workflow server: {str(e)}")

@router.post("/stop")
async def stop_workflow_server(user=Depends(get_admin_user)):
    """Stop the workflow server"""
    try:
        stopped_processes = []
        
        # Find and stop workflow processes
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if proc.info['cmdline'] and any('n8n' in str(cmd) for cmd in proc.info['cmdline']):
                    proc.terminate()
                    stopped_processes.append(proc.info['pid'])
                    
                    # Wait for graceful shutdown
                    try:
                        proc.wait(timeout=10)
                    except psutil.TimeoutExpired:
                        proc.kill()  # Force kill if not terminated gracefully
                        
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        if stopped_processes:
            return {
                "success": True,
                "message": f"Stopped workflow server processes: {stopped_processes}",
                "stopped_processes": stopped_processes
            }
        else:
            return {
                "success": True,
                "message": "No workflow server processes found running"
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to stop workflow server: {str(e)}")

@router.post("/restart")
async def restart_workflow_server(
    background_tasks: BackgroundTasks,
    user=Depends(get_admin_user)
):
    """Restart the workflow server"""
    try:
        # Stop existing processes
        await stop_workflow_server(user)
        
        # Wait for cleanup
        time.sleep(3)
        
        # Start new process
        result = await start_workflow_server(background_tasks, user)
        
        return {
            "success": True,
            "message": "Workflow server restarted successfully",
            "status": result.get("status")
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to restart workflow server: {str(e)}")

############################
# Workflow Operations
############################

@router.get("/")
async def get_workflows(user=Depends(get_verified_user)):
    """Get all workflows"""
    # Mock data - in real implementation, this would fetch from n8n API or database
    workflows = [
        {
            "id": "workflow_001",
            "name": "Welcome Automation",
            "active": True,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "nodes": [
                {"id": "trigger", "type": "webhook", "name": "Webhook Trigger"},
                {"id": "email", "type": "email", "name": "Send Email"}
            ],
            "connections": {"trigger": {"email": {"main": [0]}}}
        }
    ]
    return workflows

@router.post("/execute")
async def execute_workflow(
    request: WorkflowExecuteRequest,
    user=Depends(get_verified_user)
):
    """Execute a workflow"""
    try:
        # Mock execution - in real implementation, this would trigger n8n workflow
        return {
            "success": True,
            "execution_id": f"exec_{int(time.time())}",
            "workflow_id": request.workflow_id,
            "status": "running",
            "started_at": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to execute workflow: {str(e)}")

@router.get("/{workflow_id}")
async def get_workflow(workflow_id: str, user=Depends(get_verified_user)):
    """Get specific workflow details"""
    # Mock data - in real implementation, fetch from n8n API
    workflow = {
        "id": workflow_id,
        "name": f"Workflow {workflow_id}",
        "active": True,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z",
        "nodes": [],
        "connections": {}
    }
    return WorkflowResponse(**workflow)

############################
# Background Tasks
############################

def start_workflow_process():
    """Start the n8n workflow process"""
    try:
        # Get the NST-AI workflow directory
        workflow_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "nst-ai_workflow")
        
        if os.path.exists(workflow_dir):
            # Change to workflow directory
            os.chdir(workflow_dir)
            
            # Start n8n server
            cmd = ["npm", "run", "start"]
            process = subprocess.Popen(
                cmd,
                cwd=workflow_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=os.setsid if os.name != 'nt' else None
            )
            
            # Store process for later management
            workflow_processes['main'] = process
            
            return process.pid
        else:
            raise Exception(f"Workflow directory not found: {workflow_dir}")
            
    except Exception as e:
        raise Exception(f"Failed to start workflow process: {str(e)}")

############################
# Health Check
############################

@router.get("/health")
async def workflow_health_check():
    """Check workflow system health"""
    try:
        status = "healthy"
        checks = {
            "workflow_directory": False,
            "npm_available": False,
            "port_available": False
        }
        
        # Check workflow directory
        workflow_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "nst-ai_workflow")
        checks["workflow_directory"] = os.path.exists(workflow_dir)
        
        # Check npm availability
        try:
            subprocess.run(["npm", "--version"], capture_output=True, check=True)
            checks["npm_available"] = True
        except:
            checks["npm_available"] = False
        
        # Check port availability
        import socket
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            result = s.connect_ex(('localhost', 5678))
            checks["port_available"] = result != 0  # Port is available if connection fails
        
        # Determine overall status
        if not all(checks.values()):
            status = "unhealthy"
        
        return {
            "status": status,
            "checks": checks,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }
