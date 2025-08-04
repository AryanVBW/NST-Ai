# NST-AI Development Setup Guide 🛠️

This guide provides step-by-step instructions to successfully install, configure, and run NST-AI locally for development purposes.

---

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **Node.js** (v18 or higher) - [Download here](https://nodejs.org/)
- **Python** (v3.11 or higher) - [Download here](https://python.org/)
- **Git** - [Download here](https://git-scm.com/)
- **Terminal/Command Prompt** access

### Verify Prerequisites

```bash
# Check Node.js version
node --version

# Check Python version
python --version

# Check Git version
git --version
```

---

## 🚀 Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/AryanVBW/NST-Ai.git
cd NST-Ai
```

### Step 2: Frontend Setup

```bash
# Install frontend dependencies
npm install

# Verify installation
npm list --depth=0
```

### Step 3: Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install minimal required dependencies
pip install fastapi uvicorn python-multipart

# Verify installation
pip list
```

---

## 🏃‍♂️ Running the Application

You need to run both frontend and backend servers simultaneously. Open **two terminal windows**:

### Terminal 1: Frontend Server

```bash
# Navigate to project root (if not already there)
cd /path/to/NST-Ai

# Start frontend development server
npm run dev
```

**Expected Output:**
```
  VITE v4.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h to show help
```

### Terminal 2: Backend Server

```bash
# Navigate to backend directory
cd /path/to/NST-Ai/backend

# Activate virtual environment
source venv/bin/activate

# Set Python path and start backend server
PYTHONPATH=/path/to/NST-Ai/backend python -m uvicorn nst_ai.main:app --host 0.0.0.0 --port 8080
```

**Replace `/path/to/NST-Ai/backend` with your actual project path**

**Expected Output:**
```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8080 (Press CTRL+C to quit)
```

---

## 🌐 Accessing the Application

Once both servers are running:

- **Frontend Interface**: http://localhost:5173/
- **Backend API**: http://localhost:8080/
- **NST-AI Workflow**: Click "NST-AI Workflow" tab in the sidebar

---

## ✨ New Features Available

### 🎯 NST-AI Workflow System
- **Complete n8n Integration**: Drag-and-drop workflow builder
- **Custom NST-AI Branding**: Fully integrated design
- **Visual Node Editor**: Create automation workflows
- **Real-time Execution**: Run workflows instantly

### 🔧 How to Access Workflow Features
1. Start both frontend and backend servers
2. Open http://localhost:5173/ in your browser
3. Click on "NST-AI Workflow" in the sidebar
4. Start building your automation workflows!

---

## 🛠️ Quick Commands Reference

### Start Development Environment
```bash
# Terminal 1 - Frontend
cd NST-Ai
npm run dev

# Terminal 2 - Backend
cd NST-Ai/backend
source venv/bin/activate
PYTHONPATH=$PWD python -m uvicorn nst_ai.main:app --host 0.0.0.0 --port 8080
```

### Stop Servers
```bash
# In each terminal, press:
Ctrl + C
```

### Restart Servers
```bash
# Just re-run the start commands above
```

---

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. Port Already in Use
```bash
# Check what's using the port
lsof -i :5173  # For frontend
lsof -i :8080  # For backend

# Kill the process if needed
kill -9 <PID>
```

#### 2. Module Not Found Errors
```bash
# Ensure you're in the correct directory
pwd

# Ensure virtual environment is activated
which python  # Should show venv path

# Reinstall dependencies if needed
cd backend
pip install fastapi uvicorn python-multipart
```

#### 3. Permission Issues (macOS/Linux)
```bash
# Make scripts executable
chmod +x install.sh
chmod +x run.sh
```

#### 4. Frontend Build Issues
```bash
# Clear npm cache and reinstall
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

#### 5. Backend Import Errors
```bash
# Ensure PYTHONPATH is set correctly
export PYTHONPATH=/full/path/to/NST-Ai/backend:$PYTHONPATH

# Or use absolute path in command
cd /full/path/to/NST-Ai/backend
PYTHONPATH=$PWD python -m uvicorn nst_ai.main:app --host 0.0.0.0 --port 8080
```

### Getting Help

If you encounter issues:

1. **Check Prerequisites**: Ensure all required software is installed
2. **Verify Paths**: Make sure you're in the correct directories
3. **Check Ports**: Ensure ports 5173 and 8080 are available
4. **Environment**: Confirm virtual environment is activated
5. **GitHub Issues**: Open an issue at [NST-AI Issues](https://github.com/AryanVBW/NST-Ai/issues)

---

## 📁 Project Structure Overview

```
NST-Ai/
├── frontend (SvelteKit + Vite)
│   ├── src/
│   │   ├── lib/components/workflow/  # Workflow integration
│   │   ├── routes/(app)/workflow/    # Workflow routes
│   │   └── ...
│   ├── package.json
│   └── vite.config.ts
├── backend/ (FastAPI + Python)
│   ├── nst_ai/
│   ├── venv/           # Virtual environment
│   └── requirements.txt
└── README.md
```

---

## 🎉 Success Checklist

- [ ] Prerequisites installed (Node.js, Python, Git)
- [ ] Repository cloned successfully
- [ ] Frontend dependencies installed (`npm install`)
- [ ] Backend virtual environment created and activated
- [ ] Backend dependencies installed (fastapi, uvicorn, python-multipart)
- [ ] Frontend server running on http://localhost:5173/
- [ ] Backend server running on http://localhost:8080/
- [ ] NST-AI Workflow tab accessible in sidebar
- [ ] Both servers respond without errors

**Congratulations! 🎊 You now have NST-AI running locally with complete workflow integration!**

---

## 💡 Development Tips

- **Hot Reload**: Both servers support hot reload for development
- **Debugging**: Check browser console and terminal logs for errors
- **Workflow Testing**: Use the workflow editor to create simple test workflows
- **API Testing**: Backend API docs available at http://localhost:8080/docs
- **Environment Variables**: Check `.env` files for configuration options

Happy coding with NST-AI! 🚀
