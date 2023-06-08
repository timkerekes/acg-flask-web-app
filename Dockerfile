# Set the base image
FROM python:alpine3.18

ENV PYBASE /pybase
ENV PYTHONUSERBASE $PYBASE
ENV PATH $PYBASE/bin:$PATH

RUN pip install pipenv

WORKDIR /tmp

COPY Pipfile .
RUN pipenv lock
RUN PIP_USER=1 PIP_IGNORE_INSTALLED=1 pipenv install -d --system --ignore-pipfile

COPY . /app/notes

WORKDIR /app

EXPOSE 80

CMD ["gunicorn", "-b 0.0.0.0:80", "notes:create_app()"]
