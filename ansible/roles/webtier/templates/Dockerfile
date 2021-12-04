FROM python:3.9.5-slim
COPY . /app
WORKDIR /app
RUN pip install -U gunicorn
RUN pip install -Ur requirements.txt
ENTRYPOINT ["gunicorn", "-b", ":3000", "wsgi"]