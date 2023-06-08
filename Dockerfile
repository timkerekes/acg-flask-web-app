# Set the base image
FROM python:alpine3.18 AS base
ENV PYBASE /pybase
ENV PYTHONUSERBASE $PYBASE
ENV PATH $PYBASE/bin:$PATH


FROM base AS builder
RUN pip install pipenv
WORKDIR /tmp
COPY Pipfile .
RUN pipenv lock
RUN PIP_USER=1 PIP_IGNORE_INSTALLED=1 pipenv install -d --system --ignore-pipfile

FROM base
COPY --from=builder /pybase /pybase
COPY . /app/notes
WORKDIR /app
ENV FLASK_APP=__init__.py
EXPOSE 80
CMD ["gunicorn", "-b 0.0.0.0:80", "notes:create_app()"]
