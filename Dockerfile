# Set the base image
FROM python:3.9-alpine

ENV PYBASE /pybase
ENV PYTHONUSERBASE $PYBASE
ENV PATH $PYBASE/bin:$PATH

RUN pip install pipenv

WORKDIR /tmp

COPY Pipfile .
RUN pipenv lock
RUN PIP_USER=1 PIP_IGNORE_INSTALLED=1 pipenv install -d --system --ignore-pipfile

WORKDIR /app

COPY . .

EXPOSE 80

CMD ["gunicorn", "-b 0.0.0.0:80", "notes:create_app()"]
