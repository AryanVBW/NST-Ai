# NST-Ai: Your Personal AI Study Buddy 🚀

**NST-Ai is a powerful, open-source AI study assistant designed to help students learn, code, and research more effectively. Think of it as your personal AI tutor, always ready to assist you.**

---

## ✨ Project Highlights

NST-Ai is more than just a chatbot. It's a comprehensive tool designed for students and developers.

<p align="center">
  <img src="img/home.png" alt="NST-Ai Home Screen" width="800">
</p>

### 💬 Engaging Conversations

Have natural and dynamic conversations with your AI assistant. 

<p align="center">
  <img src="img/chat1.png" alt="NST-Ai Chat Interface 1" width="400">
  <img src="img/chat2.png" alt="NST-Ai Chat Interface 2" width="400">
</p>

### 🧠 Multiple AI Models

Switch between different AI models to get the best assistance for your specific needs.

<p align="center">
  <img src="img/model_selection.gif" alt="Model Selection GIF" width="600">
</p>

### 💻 Code Like a Pro

Get help with coding, debugging, and even run code snippets directly within the interface.

<p align="center">
  <img src="img/code_run.gif" alt="Code Run GIF" width="600">
</p>

### 🌐 Web Development Assistant

NST-Ai can assist with web development tasks, making it a great companion for your projects.

<p align="center">
  <img src="img/webdev.png" alt="Web Development with NST-Ai" width="600">
</p>

--- 

## 🚀 1-Click Installation

Get started with NST-Ai in minutes with our simple one-line installation script.

```bash
curl -fsSL https://raw.githubusercontent.com/AryanVBW/NST-Ai/main/install.sh | bash
```

After installation, simply run `nst-ai` in your terminal to start the application. The web interface will be available at [http://localhost:8080](http://localhost:8080).

For other installation methods, including Docker and pip, please refer to our [Installation Guide](INSTALLATION.md).

### 💻 Development Setup

For developers who want to run NST-AI locally with the complete workflow integration:

**📖 [Development Setup Guide](DEVELOPMENT_SETUP.md)** - Complete step-by-step instructions

**Quick Start:**
```bash
# Frontend (Terminal 1)
npm install && npm run dev

# Backend (Terminal 2) 
cd backend && source venv/bin/activate
pip install fastapi uvicorn python-multipart
PYTHONPATH=$PWD python -m uvicorn nst_ai.main:app --host 0.0.0.0 --port 8080
```

**Access Points:**
- Frontend: http://localhost:5173/
- Backend API: http://localhost:8080/
- **New!** NST-AI Workflow: Click "NST-AI Workflow" tab in sidebar

--- 

## 🎬 More Features in Action

<p align="center">
  <b>Qurion Chat</b><br>
  <img src="img/qurion_chat.gif" alt="Qurion Chat GIF" width="600">
</p>

<p align="center">
  <b>Sign-in Process</b><br>
  <img src="img/signin.gif" alt="Sign-in GIF" width="300">
  <br><i>Seamless and secure sign-in and sign-up.</i>
</p>

<p align="center">
  <img src="img/signin.png" alt="Sign In Page" width="300">
  <img src="img/signup.png" alt="Sign Up Page" width="300">
</p>


<p align="center">
  <b>Command Line Interface</b><br>
  <img src="img/cli.gif" alt="CLI GIF" width="600">
</p>


<p align="center">
  <b>Compiler Feature</b><br>
  <img src="img/compiler.gif" alt="Compiler GIF" width="600">
</p>

<p align="center">
  <b>Database Feature</b><br>
  <img src="img/databse.png" alt="Database Management" width="400">
</p>

--- 

## 🙏 Attribution and Acknowledgments

NST-Ai is proudly built upon the foundation of the open-source [Open-WebUI](https://github.com/open-webui/open-webui) project. We extend our gratitude to the original creators and the community for their incredible work.

This project is developed for **educational purposes** to serve as an AI Study Buddy.

For full attribution details, see the [ATTRIBUTION.md](ATTRIBUTION.md) file.

## 📜 License

This project is licensed under the [NST-Ai License](LICENSE), a revised BSD-3-Clause license. Please see the [LICENSE](LICENSE) file for more details.

## 💬 Support

Have questions or need help? Open an issue on our [GitHub repository](https://github.com/AryanVBW/NST-Ai/issues).

