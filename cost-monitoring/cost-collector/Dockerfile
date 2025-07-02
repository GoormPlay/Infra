FROM python:3.9-slim

WORKDIR /app

# Install enhanced requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy enhanced collector
COPY main.py .
COPY . .

EXPOSE 8080 5000

CMD ["python", "main.py"]
