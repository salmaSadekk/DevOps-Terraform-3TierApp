# Optional: containerized run, useful for local dev or if you later swap
# EC2+Ansible for ECS/EKS. Not required for the core Terraform+Ansible+EC2
# path in this project, but handy to have.

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py wsgi.py ./

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "3", "wsgi:app"]
