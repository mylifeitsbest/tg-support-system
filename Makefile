.PHONY: api bot web dev install

install:
	cd api && pip install -r requirements.txt
	cd bot && pip install -r requirements.txt
	cd web && npm install

api:
	cd api && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

bot:
	cd bot && python -m app.main

web:
	cd web && npm run dev

dev:
	make -j3 api bot web

test:
	cd api && pytest
	cd bot && pytest

docker-up:
	docker compose up --build

docker-down:
	docker compose down
