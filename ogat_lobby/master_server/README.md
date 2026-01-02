```bash
# cd into this directory first, then
python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt

# running the server (important to set workers = 1)
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 1
```