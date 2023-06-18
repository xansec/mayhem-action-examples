FROM python

RUN mkdir /api
WORKDIR /api
COPY ./api .

RUN pip install -r requirements.txt
ENV FASTAPI_ENV=test

EXPOSE 8000

ENTRYPOINT ["uvicorn", "src.main:app"]
