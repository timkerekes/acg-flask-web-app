# Set the base image
FROM python:3.9-alpine

WORKDIR /app

RUN pip install --no-cache-dir pipenv
RUN pip install python-dotenv

COPY Pipfile Pipfile.lock ./

RUN pipenv install --system --deploy --ignore-pipfile

COPY . .

ENV FLASK_APP=__init__.py

EXPOSE 5000

CMD ["flask", "run", "--host=0.0.0.0"] && ["flask", "db", "init"] && ["flask", "db", "migrate"] && ["flask", "db", "upgrade"]
