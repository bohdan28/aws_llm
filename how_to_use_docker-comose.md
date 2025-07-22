# AnythingLLM + Ollama + PostgreSQL + pgvector (Docker Setup)

This guide will get you running with AnythingLLM using Ollama and PostgreSQL (with `pgvector`) in Docker.

---

## Getting Started

### 1. Start the Docker stack

```bash
docker compose up -d
```

### 2. Connect to PostgreSQL locally

```bash
psql -h localhost -U anythingllm -d anythingllm_db -p 5432
```

### 3. Install `pgvector` extension in PostgreSQL

Inside the `psql` shell:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

---

## Set Up Ollama

### 4. Download a model (e.g., LLaMA 2)

```bash
docker exec -it ollama ollama pull llama2
```

### 5. Verify Ollama is running

Visit [http://localhost:11434](http://localhost:11434)
You should see: `Ollama is running!`

---

## Use AnythingLLM

### 6. Open AnythingLLM UI

Visit [http://localhost:3001](http://localhost:3001)

### 7. Create a new Workspace

Click **"Create Workspace"** and name it as desired.

---

## Configure AnythingLLM Settings

### 8. Set up LLM

* Go to **Settings > General > LLM**
* Choose `ollama` from the list
* Paste in this address:

  ```
  ollama:11434
  ```

### 9. Set up vector DB

* Go to **Settings > General > VectorDB**
* Choose `PostgreSQL`
* Paste in this URI:

  ```
  postgresql://anythingllm:anythingllm_pass@postgres:5432/anythingllm_db
  ```

### 10. Set up embedder

* Go to **Settings > General > Embedder**
* Choose `AnythingLLM Embedder`

---

## Done!

You're ready to start using AnythingLLM with your local Ollama model and vector database.

