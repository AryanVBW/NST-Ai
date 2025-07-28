# NST-Ai 👋





## Key Features of NST-Ai ⭐

- 🚀 **Effortless Setup**: Install seamlessly using Docker or Kubernetes (kubectl, kustomize or helm) for a hassle-free experience with support for both `:ollama` and `:cuda` tagged images.

- 🤝 **Ollama/OpenAI API Integration**: Effortlessly integrate OpenAI-compatible APIs for versatile conversations alongside Ollama models. Customize the OpenAI API URL to link with **LMStudio, GroqCloud, Mistral, OpenRouter, and more**.

- 🛡️ **Granular Permissions and User Groups**: By allowing administrators to create detailed user roles and permissions, we ensure a secure user environment. This granularity not only enhances security but also allows for customized user experiences, fostering a sense of ownership and responsibility amongst users.

- 📱 **Responsive Design**: Enjoy a seamless experience across Desktop PC, Laptop, and Mobile devices.

- 📱 **Progressive Web App (PWA) for Mobile**: Enjoy a native app-like experience on your mobile device with our PWA, providing offline access on localhost and a seamless user interface.

- ✒️🔢 **Full Markdown and LaTeX Support**: Elevate your LLM experience with comprehensive Markdown and LaTeX capabilities for enriched interaction.

- 🎤📹 **Hands-Free Voice/Video Call**: Experience seamless communication with integrated hands-free voice and video call features, allowing for a more dynamic and interactive chat environment.

- 🛠️ **Model Builder**: Easily create Ollama models via the Web UI. Create and add custom characters/agents, customize chat elements, and import models effortlessly.

- 🐍 **Native Python Function Calling Tool**: Enhance your LLMs with built-in code editor support in the tools workspace. Bring Your Own Function (BYOF) by simply adding your pure Python functions, enabling seamless integration with LLMs.

- 📚 **Local RAG Integration**: Dive into the future of chat interactions with groundbreaking Retrieval Augmented Generation (RAG) support. This feature seamlessly integrates document interactions into your chat experience. You can load documents directly into the chat or add files to your document library, effortlessly accessing them using the `#` command before a query.

- 🔍 **Web Search for RAG**: Perform web searches using providers like `SearXNG`, `Google PSE`, `Brave Search`, `serpstack`, `serper`, `Serply`, `DuckDuckGo`, `TavilySearch`, `SearchApi` and `Bing` and inject the results directly into your chat experience.

- 🌐 **Web Browsing Capability**: Seamlessly integrate websites into your chat experience using the `#` command followed by a URL. This feature allows you to incorporate web content directly into your conversations, enhancing the richness and depth of your interactions.

- 🎨 **Image Generation Integration**: Seamlessly incorporate image generation capabilities using options such as AUTOMATIC1111 API or ComfyUI (local), and OpenAI's DALL-E (external), enriching your chat experience with dynamic visual content.

- ⚙️ **Many Models Conversations**: Effortlessly engage with various models simultaneously, harnessing their unique strengths for optimal responses. Enhance your experience by leveraging a diverse set of models in parallel.

- 🔐 **Role-Based Access Control (RBAC)**: Ensure secure access with restricted permissions; only authorized individuals can access your Ollama, and exclusive model creation/pulling rights are reserved for administrators.

- 🌐🌍 **Multilingual Support**: Experience NST-Ai in your preferred language with our internationalization (i18n) support. Join us in expanding our supported languages! We're actively seeking contributors!

- 🧩 **Pipelines, NST-Ai Plugin Support**: Seamlessly integrate custom logic and Python libraries into NST-Ai using Pipelines Plugin Framework. Launch your Pipelines instance, set the OpenAI URL to the Pipelines URL, and explore endless possibilities. Examples include **Function Calling**, User **Rate Limiting** to control access, **Usage Monitoring** with tools like Langfuse, **Live Translation with LibreTranslate** for multilingual support, **Toxic Message Filtering** and much more.

- 🌟 **Continuous Updates**: We are committed to improving NST-Ai with regular updates, fixes, and new features.

Want to learn more about NST-Ai's features? Check out our [NST-Ai documentation](https://docs.nst-ai.com/features) for a comprehensive overview!

## How to Install 🚀

### 🚀 One-Line Installation (Recommended)

The easiest way to install NST-AI is using our automated installation script that detects your OS, installs all dependencies, and sets up everything for you:

```bash
curl -fsSL https://raw.githubusercontent.com/AryanVBW/NST-Ai/main/install.sh | bash
```

After installation, you can start NST-AI from anywhere by simply running:

```bash
nst-ai
```

The web interface will be available at [http://localhost:8080](http://localhost:8080)

**Features of the automated installer:**
- 🔍 Automatically detects your operating system (Linux, macOS, Windows)
- 📦 Installs all required dependencies (Python, Node.js, Git)
- ⚙️ Sets up virtual environment and installs all requirements
- 🌐 Builds the frontend application
- 🔗 Creates a global `nst-ai` command accessible from anywhere
- 🗑️ Includes an uninstall script for easy removal

**Supported Operating Systems:**
- Linux (Debian/Ubuntu, RedHat/CentOS/Fedora, Arch Linux)
- macOS (with Homebrew)
- Windows (manual Python installation required)

### Installation via Python pip 🐍

NST-Ai can be installed using pip, the Python package installer. Before proceeding, ensure you're using **Python 3.11** to avoid compatibility issues.

1. **Install NST-Ai**:
   Open your terminal and run the following command to install NST-Ai:

   ```bash
   pip install nst-ai
   ```

2. **Running NST-Ai**:
   After installation, you can start NST-Ai by executing:

   ```bash
   nst-ai serve
   ```

This will start the NST-Ai server, which you can access at [http://localhost:8080](http://localhost:8080)

### Quick Start with Docker 🐳

> [!NOTE]  
> Please note that for certain Docker environments, additional configurations might be needed. If you encounter any connection issues, our detailed guide on [NST-Ai Documentation](https://docs.nst-ai.com/) is ready to assist you.

> [!WARNING]
> When using Docker to install NST-Ai, make sure to include the `-v nst-ai:/app/backend/data` in your Docker command. This step is crucial as it ensures your database is properly mounted and prevents any loss of data.

> [!TIP]  
> If you wish to utilize NST-Ai with Ollama included or CUDA acceleration, we recommend utilizing our official images tagged with either `:cuda` or `:ollama`. To enable CUDA, you must install the [Nvidia CUDA container toolkit](https://docs.nvidia.com/dgx/nvidia-container-runtime-upgrade/) on your Linux/WSL system.

### Installation with Default Configuration

- **If Ollama is on your computer**, use this command:

  ```bash
  docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v nst-ai:/app/backend/data --name nst-ai --restart always ghcr.io/AryanVBW/nst-ai:main
  ```

- **If Ollama is on a Different Server**, use this command:

  To connect to Ollama on another server, change the `OLLAMA_BASE_URL` to the server's URL:

  ```bash
  docker run -d -p 3000:8080 -e OLLAMA_BASE_URL=https://example.com -v nst-ai:/app/backend/data --name nst-ai --restart always ghcr.io/AryanVBW/nst-ai:main
  ```

- **To run NST-Ai with Nvidia GPU support**, use this command:

  ```bash
  docker run -d -p 3000:8080 --gpus all --add-host=host.docker.internal:host-gateway -v nst-ai:/app/backend/data --name nst-ai --restart always ghcr.io/AryanVBW/nst-ai:cuda
  ```

### Installation for OpenAI API Usage Only

- **If you're only using OpenAI API**, use this command:

  ```bash
  docker run -d -p 3000:8080 -e OPENAI_API_KEY=your_secret_key -v nst-ai:/app/backend/data --name nst-ai --restart always ghcr.io/AryanVBW/nst-ai:main
  ```

### Installing NST-Ai with Bundled Ollama Support

This installation method uses a single container image that bundles NST-Ai with Ollama, allowing for a streamlined setup via a single command. Choose the appropriate command based on your hardware setup:

- **With GPU Support**:
  Utilize GPU resources by running the following command:

  ```bash
  docker run -d -p 3000:8080 --gpus=all -v ollama:/root/.ollama -v nst-ai:/app/backend/data --name nst-ai --restart always ghcr.io/AryanVBW/nst-ai:ollama
  ```

- **For CPU Only**:
  If you're not using a GPU, use this command instead:

  ```bash
  docker run -d -p 3000:8080 -v ollama:/root/.ollama -v nst-ai:/app/backend/data --name nst-ai --restart always ghcr.io/AryanVBW/nst-ai:ollama
  ```

Both commands facilitate a built-in, hassle-free installation of both NST-Ai and Ollama, ensuring that you can get everything up and running swiftly.

After installation, you can access NST-Ai at [http://localhost:3000](http://localhost:3000). Enjoy! 😄

### Other Installation Methods

We offer various installation alternatives, including non-Docker native installation methods, Docker Compose, Kustomize, and Helm. Visit our [NST-Ai Documentation](https://docs.nst-ai.com/getting-started/) for comprehensive guidance.

Look at the [Local Development Guide](https://docs.nst-ai.com/getting-started/advanced-topics/development) for instructions on setting up a local development environment.

### Troubleshooting

Encountering connection issues? Our [NST-Ai Documentation](https://docs.nst-ai.com/troubleshooting/) has got you covered.

#### NST-Ai: Server Connection Error

If you're experiencing connection issues, it's often due to the WebUI docker container not being able to reach the Ollama server at 127.0.0.1:11434 (host.docker.internal:11434) inside the container . Use the `--network=host` flag in your docker command to resolve this. Note that the port changes from 3000 to 8080, resulting in the link: `http://localhost:8080`.

**Example Docker Command**:

```bash
docker run -d --network=host -v nst-ai:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name nst-ai --restart always ghcr.io/AryanVBW/nst-ai:main
```

### Keeping Your Docker Installation Up-to-Date

In case you want to update your local Docker installation to the latest version, you can do it with [Watchtower](https://containrrr.dev/watchtower/):

```bash
docker run --rm --volume /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once nst-ai
```

In the last part of the command, replace `nst-ai` with your container name if it is different.

Check our Updating Guide available in our [NST-Ai Documentation](https://docs.nst-ai.com/getting-started/updating).

### Using the Dev Branch 🌙

> [!WARNING]
> The `:dev` branch contains the latest unstable features and changes. Use it at your own risk as it may have bugs or incomplete features.

If you want to try out the latest bleeding-edge features and are okay with occasional instability, you can use the `:dev` tag like this:

```bash
docker run -d -p 3000:8080 -v nst-ai:/app/backend/data --name nst-ai --add-host=host.docker.internal:host-gateway --restart always ghcr.io/AryanVBW/nst-ai:dev
```

### Offline Mode

If you are running NST-Ai in an offline environment, you can set the `HF_HUB_OFFLINE` environment variable to `1` to prevent attempts to download models from the internet.

```bash
export HF_HUB_OFFLINE=1
```

## What's Next? 🌟

Discover upcoming features on our roadmap in the [NST-Ai Documentation](https://docs.nst-ai.com/roadmap/).

## Attribution and Acknowledgments 🙏

**NST-Ai is built upon the excellent foundation of [Open-WebUI](https://github.com/open-webui/open-webui)**, originally created by Timothy Jaeryang Baek and the Open-WebUI community. We deeply appreciate their outstanding work and contribution to the open-source community.

### Educational Purpose
This project is developed **strictly for educational purposes** as an AI Study Buddy to assist students in their academic journey. It is not intended for commercial use and serves as a demonstration of AI technology in educational contexts.

### Original Project Recognition
- **Original Project**: [Open-WebUI](https://github.com/open-webui/open-webui)
- **Original Author**: Timothy Jaeryang Baek
- **Original License**: MIT License / BSD 3-Clause License

For complete attribution details, copyright information, and compliance statements, please see our [ATTRIBUTION.md](ATTRIBUTION.md) file.

## License 📜

This project is licensed under the [NST-Ai License](LICENSE), a revised BSD-3-Clause license that maintains compatibility with the original Open-WebUI licensing terms. You receive all the same rights as the classic BSD-3 license: you can use, modify, and distribute the software, including in proprietary and commercial products, with minimal restrictions. The only additional requirement is to preserve the "NST-Ai" branding, as detailed in the LICENSE file. For full terms, see the [LICENSE](LICENSE) document. 📄

## Support 💬

If you have any questions, suggestions, or need assistance, please open an issue on our GitHub repository to connect with us! 🤝

## Star History

<a href="https://star-history.com/#AryanVBW/NST-Ai&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=AryanVBW/NST-Ai&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=AryanVBW/NST-Ai&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=AryanVBW/NST-Ai&type=Date" />
  </picture>
</a>

---

Created by [Vivek W](https://github.com/AryanVBW) - Let's make NST-Ai even more amazing together! 💪
